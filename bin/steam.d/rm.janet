#!/usr/bin/env janet
# Remove a non-Steam game from HOST: shortcut, files and art.
#
# SYNOPSIS:
#   hey .steam rm HOST GAME... [--saves]
#
# DESCRIPTION:
#   Steam lacks a "uninstall game" for non-steam games, so I use this. Steam's
#   "remove from library" only drops the shortcut. This removes that and the
#   files, the art, and the prefix. Only use this on games added through `hey
#   .steam push`.
#
# OPTIONS:
#   --saves
#     Delete the Proton prefix too.
#
# ARGUMENTS:
#   1 HOST @ssh-host
#   * GAME @steam-games

(use hey)
(use sh)
(import hey/steam)

(defn- rm-game [host shortcut roots uid saves?]
  (def name (shortcut :name))
  (def appid (shortcut :appid))
  (def start-dir (string/trimr (shortcut :start-dir) "/"))
  (def ours? (some |(string/has-prefix? (string $0 "/") start-dir) roots))
  (if ours?
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

(defmain [_ host & games &opts saves? [--saves]]
  (when (or (nil? host) (empty? games)) (usage))
  (def uid (steam/user-id (steam/steam-dir)))
  (def remotes (steam/remote-shortcuts host uid))
  (def shortcuts
    (seq [game :in games]
      (or (steam/find-shortcut remotes game)
          (abort "No shortcut called %q on %s; `hey .steam ls %s` knows the names" game host host))))
  (unless (dryrun?) (steam/ensure-debugging host))
  (def home (steam/remote-home host))
  (def roots (distinct [(steam/remote-games-dir host home) (path/join home "Games")]))
  (each shortcut shortcuts
    (rm-game host shortcut roots uid saves?)))
