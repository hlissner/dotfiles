#!/usr/bin/env janet
# Install a non-Steam PC game from RomM to HOST, saves included.
#
# SYNOPSIS:
#   hey .steam push HOST GAME... [-e EXE] [-c TOOL] [-l OPTS] [--no-art] [--no-saves] [--seed] [--force] [--direct] [-g]
#
# DESCRIPTION:
#   Installs a game from RomM (see `hey .steam ls romm` to list them) to a
#   remote HOST (could be a SteamOS device or an Android running GameNative;
#   they must have sshd running). The game must be stored as a zip or 7z file
#   (iso's are refused), which is extracted locally in ~/.cache/hey/romm/ before
#   it is pushed over ssh. If my NAS is hooked up at /media/nas, then game
#   archives are copied from there instead of downloaded from the romm server.
#
#   On a Steam HOST (CEF debugger must be on) it's then registered in the
#   running Steam over the CEF debugger. If the game has a steam shortcut on
#   this system, its art, save files, and proton prefix go with it.
#
#   An Android HOST (e.g. my Retroids over Termux's sshd) are expected to be
#   using GameNative. Games are deployed to GameNative/CustomGames/GAME on their
#   SD card, a folder GameNative scans on its own (open its library once), and
#   the saves -- the user dir, as a tree -- to Download/GameNative/GAME/, the
#   folder its Import Files menu and its in-container file manager (D:) read
#   from.
#
#   Push to `romm` (a special target) to upload a game's local save(s) to RomM
#   directly.
#
# OPTIONS:
#   -e, --exe PATH
#     The exe to run, relative to the game dir. Only needed when the archive holds
#     more than one and no shortcut here settles it; one GAME at a time.
#   -c, --compat TOOL
#     Compat tool to pin, e.g. proton_experimental (the default) or GE-Proton.
#     An empty string leaves Steam to its default.
#   -l, --launch-options OPTS
#     Launch options for the shortcut on HOST. Default: none. The local ones
#     are never copied; mine are gamescope flags for this monitor.
#   --no-art
#     Don't send the custom artwork.
#   --no-saves
#     Game and shortcut only.
#   --seed
#     Create the prefix's user dir and send the saves even if the game has
#     never run on HOST. Proton's first run fills in around existing files.
#   --force
#     Overwrite saves on RomM and on HOST even where they're newer than mine.
#   --direct
#     Copy the shortcut's start dir and rsync its saves straight to HOST, as
#     before RomM; nothing is downloaded or uploaded.
#   -g, --gamenative
#     Treat HOST as an Android/GameNative device without asking it. Detected
#     otherwise; this is for --dry-run, which never talks to HOST.
#
# ARGUMENTS:
#   1 HOST @steam-host
#   * GAME @steam-games

(use hey)
(use sh)
(import hey/steam)
(import hey/romm)
(import hey/romm/retroid)

(defn- push-saves [host game remote entry &named seed? force?]
  (def name (game :name))
  (def local (when (game :appid) (steam/prefix-dir (steam/steam-dir) (game :appid))))
  (steam/romm-saves name remote
                    (if local (steam/romm-saves name local entry :direction :upload :force? force?) entry)
                    :host host :direction :download :force? force? :mkpath? seed?))

(defn- romm-save-here
  ``RomM's newest save of GAME, unpacked under the cache for a host that can't
  run the helper; nil when RomM holds none.``
  [game entry]
  (if (nil? (entry :latest))
    (echof :warn "%s has no proton save on RomM yet, and no prefix here; nothing to send" (game :name))
    (let [dir (path :cache "romm" "saves" (retroid/folder-name (game :name)))]
      ($? rm -rf ,dir)
      (steam/romm-saves (game :name) dir entry :direction :download :mkpath? true)
      (when (or (dryrun?) (path/directory? dir))
        dir))))

(defn- copy-game
  "GAME's start dir to REMOTE-DIR on HOST; MKDIR-ERROR when the dir can't be made."
  [host game remote-dir mkdir-error]
  (def start-dir (string/trimr (game :start-dir) "/"))
  (echof :g "%s: copying %s to %s:%s" (game :name) (path/abbrev start-dir) host remote-dir)
  (unless (do? $? ssh ,host ,(string "mkdir -p " (shell-quote remote-dir)))
    (abort mkdir-error remote-dir host))
  (unless (do? $? rsync -rltDP ,(string start-dir "/") ,(string host ":" remote-dir "/"))
    (abort "Couldn't copy %s to %s" (game :name) host)))

(defn- push-game [host game dest &named compat launch-options art? saves? seed? force? entry]
  (def dir (steam/steam-dir))
  (def uid (steam/user-id dir))
  (def {:dir remote-dir :exe remote-exe} (steam/relocate game dest))
  # The game first: a shortcut to files that never arrived is worse than no
  # shortcut.
  (copy-game host game remote-dir "Couldn't create %s on %s")
  (def art (if (and art? (game :appid)) (steam/artwork dir uid (game :appid) (game :icon)) @[]))
  (def reply
    (if (dryrun?)
      (do (printf "steam: AddShortcut %q exe=%q dir=%q opts=%q compat=%q art=%s"
                  (game :name) remote-exe remote-dir launch-options compat
                  (string/join (map |(string ($0 :type)) art) ","))
          {:appid 0 :created true :exe remote-exe})
      (steam/cdp-eval host (steam/register-js {:name (game :name)
                                               :exe remote-exe
                                               :start-dir remote-dir
                                               :launch-options launch-options
                                               :compat compat
                                               :art (steam/encode-art art)}))))
  (def appid (reply :appid))
  (echof :g "%s: %s on %s as %d" (game :name) (if (reply :created) "added" "already") host appid)
  (unless (= (reply :exe) remote-exe)
    (echof :warn "%s's shortcut on %s ran %s; it now runs %s, and the old copy is still there"
           (game :name) host (reply :exe) remote-exe))
  (when saves?
    (def local (steam/prefix-here game))
    (def remote (steam/prefix-dir steam/remote-steam-dir appid))
    (cond
      entry
      (push-saves host game remote entry :seed? seed? :force? force?)

      (nil? local)
      (echof :warn "%s has no prefix here (never launched?); no saves to send" (game :name))

      (and (not seed?) (not (dryrun?)) (not (steam/remote-has-prefix? host appid)))
      (echof :warn "%s has no prefix on %s yet. Launch it there once, then push again (or --seed)"
             (game :name) host)

      (unless (do? $? rsync -rltDzP ,;(if force? [] ["-u"]) ,;(if seed? ["--mkpath"] [])
                   ,;steam/excludes
                   ,(string local "/") ,(string host ":" remote "/"))
        (abort "Couldn't send %s's saves to %s" (game :name) host))))
  (echo :check (fmt "%s → %s (%d)" (game :name) host appid)))

(defn- push-game-android [host game games-dir &named saves? force? entry]
  (def name (game :name))
  (def folder (retroid/folder-name name))
  (def {:dir remote-dir} (steam/relocate game games-dir folder))
  (copy-game host game remote-dir "Couldn't create %s on %s. Termux needs \"All files access\" to write to the SD card")
  (echo :g (retroid/setup-hint games-dir))
  (when saves?
    (def src (or (steam/prefix-here game)
                 (if entry
                   (romm-save-here game entry)
                   (echof :warn "%s has no prefix here (never launched?); no saves to send" name))))
    (when src
      (def remote (retroid/mailbox-dir folder))
      # mkdir over ssh, not --mkpath: the Retroid's rsync 3.5 balks at a
      # symlinked parent. No -l: Android's shared storage can't hold symlinks.
      (unless (do? $? ssh ,host ,(string "mkdir -p " (shell-quote remote)))
        (abort "Couldn't create %s on %s" remote host))
      (unless (do? $? rsync -rtDzP ,;(if force? [] ["-u"]) ,;steam/excludes
                   ,(string src "/") ,(string host ":" remote "/"))
        (abort "Couldn't send %s's saves to %s" name host))
      (echo :warn (retroid/import-hint folder))))
  (echo :check (fmt "%s → %s" name host)))

(defmain [_ host & games &opts
          exe            [-e --exe path]
          compat         [-c --compat tool]
          launch-options [-l --launch-options opts]
          no-art?        [--no-art]
          no-saves?      [--no-saves]
          seed?          [--seed]
          force?         [--force]
          direct?        [--direct]
          gamenative?    [-g --gamenative]]
  (when (or (nil? host) (empty? games)) (usage))
  (def romm? (= host romm/pseudo-host))
  (when (and romm? direct?)
    (abort "%s isn't an ssh host; --direct needs one" host))
  (when (and romm? no-saves?)
    (abort "Saves are all %s takes; nothing to do with --no-saves" host))
  (when (and exe (or direct? romm?))
    (abort "-e picks a ROM's exe; a shortcut here already has one"))
  (when (and exe (> (length games) 1))
    (abort "-e names one exe; push one GAME at a time with it"))
  # Every name has to check out before the first byte leaves, or a typo in the
  # second game strands the first half-done.
  (def dir (steam/steam-dir))
  (def all (steam/shortcuts (slurp (steam/shortcuts-file dir (steam/user-id dir)))))
  (def roms @{})   # by the name each target ends up with
  (def targets
    (if (or direct? romm?)
      (seq [game :in games]
        (def s (or (steam/find-shortcut all game)
                   (abort "No shortcut called %q here; `hey .steam ls` knows the names" game)))
        (try (steam/relocate s "/") ([e] (abort "%s" e)))
        s)
      (let [pid (romm/platform-id)
            found (seq [game :in games] [game (steam/find-rom game pid)])]
        (seq [[game rom] :in found]
          (def s (or (steam/find-shortcut all game) (steam/find-shortcut all (rom :title))))
          (def g (steam/romm-game rom (steam/unpack-rom rom) :shortcut s :exe exe))
          (put roms (g :name) rom)
          g))))
  (def android? (and (not romm?) (or gamenative? (and (not (dryrun?)) (retroid/android? host)))))
  (when (and (or romm? android?) (or compat launch-options no-art? seed?))
    (echof :warn "%s has no compat tools, launch options, art or prefixes to seed; -c/-l/--no-art/--seed ignored"
           (if romm? "RomM" "GameNative")))
  (def entries
    (if (or direct? no-saves?) {} (steam/romm-entries (map |($0 :name) targets) :roms roms)))
  (cond
    romm?
    (each game targets
      (steam/romm-saves (game :name) (steam/prefix-dir dir (game :appid)) (entries (game :name))
                        :direction :upload :force? force?)
      (echo :check (fmt "%s → %s" (game :name) host)))

    android?
    (let [games-dir (if (dryrun?) (string "$SDCARD/" retroid/games-subdir) (retroid/games-dir host))]
      (each game targets
        (push-game-android host game games-dir :saves? (not no-saves?) :force? force? :entry (entries (game :name)))))

    (do
      (def home (if (dryrun?) "$HOME" (steam/remote-home host)))
      (unless (dryrun?) (steam/ensure-debugging host))
      (def dest (if (dryrun?) "$STEAM_LIBRARY/Games" (steam/remote-games-dir host home)))
      (each game targets
        (push-game host game dest
                   :compat (or compat "proton_experimental")
                   :launch-options (or launch-options "")
                   :art? (not no-art?)
                   :saves? (not no-saves?)
                   :seed? seed?
                   :force? force?
                   :entry (entries (game :name)))))))
