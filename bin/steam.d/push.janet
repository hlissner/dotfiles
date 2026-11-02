#!/usr/bin/env janet
# Copy a non-Steam game and its Proton saves to HOST, and add it to Steam there.
#
# SYNOPSIS:
#   hey .steam push HOST GAME... [-c TOOL] [-l OPTS] [--no-art] [--no-saves] [--seed] [--force]
#
# DESCRIPTION:
#   For each GAME (a shortcut name; see `hey .steam ls`): rsync its start dir to
#   HOST, register it in the running Steam over the CEF debugger (same name,
#   art, and a pinned compat tool), then rsync the saves -- the Windows user dir
#   inside its Proton prefix -- into the prefix HOST's Steam gave it.
#
#   A GAME already on HOST keeps its appid, so its prefix and saves survive a
#   move: the shortcut is pointed at wherever the files landed this time.
#
#   Games land in a Games/ relative to Steam's default library root on HOST
#   (e.g. an SD card) or in $HOME/Games when that library is the one under
#   $HOME.
#
#   Saves only go where a prefix already exists, i.e. once the game has been
#   launched on HOST. Nothing is ever deleted on either side, and a newer save
#   on HOST is left alone unless --force.
#
#   Steam on HOST must be running with its CEF debugger on. The first push turns
#   it on (a marker file) and tells you to restart Steam.
#
# OPTIONS:
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
#     Overwrite saves on HOST even where they're newer than mine.
#
# ARGUMENTS:
#   1 HOST @ssh-host
#   * GAME @steam-games

(use hey)
(use sh)
(import hey/steam)

(defn- push-game [host shortcut dest &named compat launch-options art? saves? seed? force?]
  (def dir (steam/steam-dir))
  (def uid (steam/user-id dir))
  (def {:dir remote-dir :exe remote-exe} (steam/relocate shortcut dest))
  (def start-dir (string/trimr (shortcut :start-dir) "/"))

  # The game first: a shortcut to files that never arrived is worse than no
  # shortcut.
  (echof :g "%s: copying %s to %s:%s" (shortcut :name) (path/abbrev start-dir) host remote-dir)
  (unless (and (do? $? ssh ,host ,(string "mkdir -p " (shell-quote remote-dir)))
               (do? $? rsync -rltDP ,(string start-dir "/") ,(string host ":" remote-dir "/")))
    (abort "Couldn't copy %s to %s" (shortcut :name) host))

  (def art (if art? (steam/artwork dir uid (shortcut :appid) (shortcut :icon)) @[]))
  (def js (steam/register-js {:name (shortcut :name)
                              :exe remote-exe
                              :start-dir remote-dir
                              :launch-options launch-options
                              :compat compat
                              :art (steam/encode-art art)}))
  (def reply
    (if (dryrun?)
      (do (printf "steam: AddShortcut %q exe=%q dir=%q opts=%q compat=%q art=%s"
                  (shortcut :name) remote-exe remote-dir launch-options compat
                  (string/join (map |(string ($0 :type)) art) ","))
          {:appid 0 :created true :exe remote-exe})
      (steam/cdp-eval host js)))
  (def appid (reply :appid))
  (echof :g "%s: %s on %s as %d" (shortcut :name) (if (reply :created) "added" "already") host appid)
  (unless (= (reply :exe) remote-exe)
    (echof :warn "%s's shortcut on %s ran %s; it now runs %s, and the old copy is still there"
           (shortcut :name) host (reply :exe) remote-exe))

  (when saves?
    (def local (steam/prefix-dir dir (shortcut :appid)))
    (def remote (steam/prefix-dir steam/remote-steam-dir appid))
    (cond
      (not (path/directory? local))
      (echof :warn "%s has no prefix here (never launched?); no saves to send" (shortcut :name))

      (and (not seed?) (not (dryrun?)) (not (steam/remote-has-prefix? host appid)))
      (echof :warn "%s has no prefix on %s yet. Launch it there once, then push again (or --seed)"
             (shortcut :name) host)

      (unless (do? $? rsync -rltDzP ,;(if force? [] ["-u"]) ,;(if seed? ["--mkpath"] [])
                   ,;steam/excludes
                   ,(string local "/") ,(string host ":" remote "/"))
        (abort "Couldn't send %s's saves to %s" (shortcut :name) host))))
  (echo :check (fmt "%s → %s (%d)" (shortcut :name) host appid)))

(defmain [_ host & games &opts
          compat         [-c --compat tool]
          launch-options [-l --launch-options opts]
          no-art?        [--no-art]
          no-saves?      [--no-saves]
          seed?          [--seed]
          force?         [--force]]
  (when (or (nil? host) (empty? games)) (usage))
  # Every name has to check out before the first byte leaves, or a typo in the
  # second game strands the first half-done.
  (def dir (steam/steam-dir))
  (def all (steam/shortcuts (slurp (steam/shortcuts-file dir (steam/user-id dir)))))
  (def shortcuts
    (seq [game :in games]
      (def s (or (steam/find-shortcut all game)
                 (abort "No shortcut called %q here; `hey .steam ls` knows the names" game)))
      (try (steam/relocate s "/") ([e] (abort "%s" e)))
      s))
  (def home (if (dryrun?) "$HOME" (steam/remote-home host)))
  (unless (dryrun?) (steam/ensure-debugging host))
  (def dest (if (dryrun?) "$STEAM_LIBRARY/Games" (steam/remote-games-dir host home)))
  (each shortcut shortcuts
    (push-game host shortcut dest
               :compat (or compat "proton_experimental")
               :launch-options (or launch-options "")
               :art? (not no-art?)
               :saves? (not no-saves?)
               :seed? seed?
               :force? force?)))
