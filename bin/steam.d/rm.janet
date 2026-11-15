#!/usr/bin/env janet
# Remove a non-Steam game from HOST: shortcut, files and art.
#
# SYNOPSIS:
#   hey .steam rm HOST GAME... [--saves] [-g]
#
# DESCRIPTION:
#   Steam lacks a "uninstall game" for non-steam games, so I use this. Steam's
#   "remove from library" only drops the shortcut. This removes that and the
#   files, the art, and the prefix. Only use this on games added through `hey
#   .steam push`. Also supports Android HOSTs (using GameNative), which deletes
#   the game from ~/GameNative/CustomGames. DOES NOT TOUCH SAVES ON ROMM.
#
#   Note that saves can't be synced without root access, so they're synced to
#   ~/Download/GameNative/<GAME>/ and that's what this command deletes. To
#   delete the actual saves it must be done manually through GameNative's UI.
#
# OPTIONS:
#   --saves
#     Delete the Proton prefix too.
#   -g, --gamenative
#     Treat HOST as an Android/GameNative device (skipping auto-detection).
#
# ARGUMENTS:
#   1 HOST @ssh-host
#   * GAME @steam-games

(use hey)
(use sh)
(import hey/steam)
(import hey/romm)
(import hey/romm/retroid)

(defn- rm-game-pc [host shortcut roots uid saves?]
  (def name (shortcut :name))
  (def appid (shortcut :appid))
  (def start-dir (string/trimr (shortcut :start-dir) "/"))
  (if (some |(string/has-prefix? (string $0 "/") start-dir) roots)
    (unless (do? $? ssh ,host ,(string "rm -rf " (shell-quote start-dir)))
      (abort "Couldn't delete %s on %s" start-dir host))
    (echof :warn "%s runs from %s, which push didn't make; leaving it alone" name start-dir))
  (if (dryrun?)
    (printf "steam: RemoveShortcut %d (%s)" appid name)
    (steam/cdp-eval host (steam/remove-js appid)))
  (unless (do? $? ssh ,host ,(string "rm -f " (string/join (steam/art-globs steam/remote-steam-dir uid appid) " ")))
    (abort "Couldn't delete %s's art on %s" name host))
  (def prefix (path/join steam/remote-steam-dir "steamapps/compatdata" (string appid)))
  (if saves?
    (unless (do? $? ssh ,host ,(string "rm -rf " (shell-quote prefix)))
      (abort "Couldn't delete %s's prefix on %s" name host))
    (echof :warn "%s's prefix (and saves) are still at %s:%s; --saves deletes them" name host prefix))
  (echo :check (fmt "%s ✗ %s (%d)" name host appid)))

(defn- rm-game-android [host game saves?]
  (def name (game :name))
  (def mailbox (retroid/mailbox-dir name))
  (unless (do? $? ssh ,host ,(string "rm -rf " (shell-quote (game :dir))))
    (abort "Couldn't delete %s on %s" (game :dir) host))
  (if saves?
    (unless (do? $? ssh ,host ,(string "rm -rf " (shell-quote mailbox)))
      (abort "Couldn't delete %s's mailbox on %s" name host))
    (when (game :mbx)
      (echof :warn "%s's exported saves are still at %s:%s; --saves deletes them" name host mailbox)))
  (echof :warn "GameNative still lists %s, and its container holds the real saves; remove both in its UI" name)
  (echo :check (fmt "%s ✗ %s" name host)))

(defmain [_ host & games &opts saves? [--saves] gamenative? [-g --gamenative]]
  (when (or (nil? host) (empty? games)) (usage))
  (when (= host romm/pseudo-host)
    (abort "%s holds saves, not games; delete those in its UI" host))
  (defn lookup
    "Each of GAMES in REMOTES, by FIND; or an abort naming the first that isn't."
    [remotes find what]
    (seq [game :in games]
      (or (find remotes game)
          (abort "No %s called %q on %s; `hey .steam ls %s` knows the names" what game host host))))
  (if (or gamenative? (retroid/android? host))
    (each game (lookup (retroid/games host) retroid/find-game "game")
      (rm-game-android host game saves?))
    (do
      (def uid (steam/user-id (steam/steam-dir)))
      (def shortcuts (lookup (steam/remote-shortcuts host uid) steam/find-shortcut "shortcut"))
      (unless (dryrun?) (steam/ensure-debugging host))
      (def home (steam/remote-home host))
      (def roots (distinct [(steam/remote-games-dir host home) (path/join home "Games")]))
      (each shortcut shortcuts
        (rm-game-pc host shortcut roots uid saves?)))))
