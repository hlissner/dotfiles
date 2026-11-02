#!/usr/bin/env janet
# Copy a non-Steam game's Proton saves back from HOST.
#
# SYNOPSIS:
#   hey .steam pull HOST GAME... [--force]
#
# DESCRIPTION:
#   The opposite of `push`'s last step: pulls the save files from HOST for GAME
#   to this system. Use `hey .steam ls` to look up shortcut names. Has no side
#   effects on the remote. Will do nothing if the local save files are newer
#   (unless --force).
#
# OPTIONS:
#   --force
#     Overwrite saves here even where they're newer than HOST's.
#
# ARGUMENTS:
#   1 HOST @ssh-host
#   * GAME @steam-games

(use hey)
(use sh)
(import hey/steam)

(defn- pull-game [host name remotes force?]
  (def dir (steam/steam-dir))
  (def uid (steam/user-id dir))
  (def mine
    (or (steam/find-shortcut (steam/shortcuts (slurp (steam/shortcuts-file dir uid))) name)
        (abort "No shortcut called %q here; `hey .steam ls` knows the names" name)))
  (def theirs
    (or (steam/find-shortcut remotes (mine :name))
        (abort "No shortcut called %q on %s; `hey .steam ls %s` knows the names" (mine :name) host host)))
  (def local (steam/prefix-dir dir (mine :appid)))
  (unless (path/directory? local)
    (abort "%s has no prefix here; launch it once so there's somewhere to put the saves" (mine :name)))
  (def remote (steam/prefix-dir steam/remote-steam-dir (theirs :appid)))
  (unless (do? $? rsync -rltDzP ,;(if force? [] ["-u"])
               ,;steam/excludes
               ,(string host ":" remote "/") ,(string local "/"))
    (abort "Couldn't fetch %s's saves from %s" (mine :name) host))
  (echo :check (fmt "%s ← %s (%d)" (mine :name) host (theirs :appid))))

(defmain [_ host & games &opts force? [--force]]
  (when (or (nil? host) (empty? games)) (usage))
  (def remotes (steam/remote-shortcuts host))
  (each game games
    (pull-game host game remotes force?)))
