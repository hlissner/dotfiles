#!/usr/bin/env janet
# Pulls a non-Steam PC game's save files from HOST.
#
# SYNOPSIS:
#   hey .steam pull HOST GAME... [--force] [--direct] [-g]
#
# DESCRIPTION:
#   Pulls only the save files from HOST for GAME, to this system. Saves go
#   through RomM too. GAME is a non-steam shortcut name; use `hey .steam ls` to
#   look those up. Will do nothing if local saves are newer than the remote's
#   (use --force to override).
#
#   On an Android HOST (GameNative) the saves are whatever is in Download/
#   GameNative/GAME/, because the device needs to be rooted to read directly
#   from the container. Use the Export Files interface to export save files
#   before running this command.
#
# OPTIONS:
#   --force
#     Overwrite saves on RomM and here even where they're newer than HOST's.
#   --direct
#     Rsync the saves straight from HOST without uploading to RomM.
#   -g, --gamenative
#     Treat HOST as an Android/GameNative device without questioning it.
#
# ARGUMENTS:
#   1 HOST @steam-host
#   * GAME @steam-games

(use hey)
(use sh)
(import hey/steam)
(import hey/romm)
(import hey/romm/retroid)

(defn- shortcut-here
  "My shortcut called NAME, or whose folder on a Retroid would be; nil otherwise."
  [name]
  (def dir (steam/steam-dir))
  (def shortcuts (steam/shortcuts (slurp (steam/shortcuts-file dir (steam/user-id dir)))))
  (or (steam/find-shortcut shortcuts name)
      (let [lower (string/ascii-lower name)]
        (find |(= lower (string/ascii-lower (retroid/folder-name ($0 :name)))) shortcuts))))

(defn- shortcut-here! [name]
  (or (shortcut-here name)
      (abort "No shortcut called %q here; `hey .steam ls` knows the names" name)))

(defn- local-saves
  "Where SHORTCUT's saves go here, which has to exist already."
  [shortcut]
  (or (steam/prefix-here shortcut)
      (abort "%s has no prefix here; launch it once so there's somewhere to put the saves" (shortcut :name))))

(defn- resolve
  ``NAME here and on HOST (REMOTES is HOST's shortcuts): {:mine :theirs :local},
  the two shortcuts and my prefix's user dir, every one of which has to exist.``
  [host name remotes]
  (def mine (shortcut-here! name))
  (def theirs
    (or (steam/find-shortcut remotes (mine :name))
        (abort "No shortcut called %q on %s; `hey .steam ls %s` knows the names" (mine :name) host host)))
  {:mine mine :theirs theirs :local (local-saves mine)})

(defn- pull-game
  ``HOST's saves for GAME (from resolve) to here: through RomM -- up from
  HOST, down into my prefix -- when ENTRY is RomM's side of it, straight by
  rsync otherwise.``
  [host game force? &opt entry]
  (def {:mine mine :theirs theirs :local local} game)
  (def name (mine :name))
  (def remote (steam/prefix-dir steam/remote-steam-dir (theirs :appid)))
  (if entry
    (steam/romm-saves name local (steam/romm-saves name remote entry :host host :direction :upload :force? force?)
                      :direction :download :force? force?)
    (unless (do? $? rsync -rltDzP ,;(if force? [] ["-u"]) ,;steam/excludes
                 ,(string host ":" remote "/") ,(string local "/"))
      (abort "Couldn't fetch %s's saves from %s" name host)))
  (echo :check (fmt "%s ← %s (%d)" name host (theirs :appid))))

(defn- pull-game-android
  ``HOST's export of NAME (GAMES is HOST's list) up to RomM, then down into my
  prefix when I have one. A shortcut here is optional; without one the name
  is the folder's. --direct is the export straight into my prefix.``
  [host name games force? direct?]
  (def mine (shortcut-here name))
  (def theirs
    (or (retroid/find-game games name)
        (when mine (retroid/find-game games (mine :name)))
        (abort "No game called %q on %s; `hey .steam ls %s` knows the names" name host host)))
  (def title (if mine (mine :name) (theirs :name)))
  (def local (when mine (steam/prefix-here mine)))
  (unless (theirs :mbx)
    (abort "%s has no export on %s. %s" title host (retroid/export-hint (theirs :name))))
  (def src (string host ":" (retroid/mailbox-dir (theirs :name)) "/"))
  (defn fetch [dest & flags]
    (unless (do? $? rsync -rltDzP ,;flags ,;steam/excludes ,src ,(string dest "/"))
      (abort "Couldn't fetch %s's saves from %s" title host)))
  (if direct?
    (fetch (or local (abort "%s has no prefix here; launch it once so there's somewhere to put the saves" title))
           ;(if force? [] ["-u"]))
    # RomM first, so a game it doesn't know stops this before the device is read.
    (let [entry ((steam/romm-entries [title]) title)
          scratch (path :cache "romm" "saves" (retroid/folder-name title))]
      ($? rm -rf ,scratch)
      (do? $ mkdir -p ,scratch)
      (fetch scratch)
      (def uploaded (steam/romm-saves title scratch entry :direction :upload :force? force?))
      (if local
        (steam/romm-saves title local uploaded :direction :download :force? force?)
        (echof :warn "%s has no prefix here; its save is on RomM, and `hey .steam pull romm %q` brings it down once it has one"
               title title))))
  (echo :check (fmt "%s ← %s" title host)))

(defmain [_ host & games &opts force? [--force] direct? [--direct] gamenative? [-g --gamenative]]
  (when (or (nil? host) (empty? games)) (usage))
  (def romm? (= host romm/pseudo-host))
  (when (and romm? direct?)
    (abort "%s isn't an ssh host; --direct needs one" host))
  (cond
    romm?
    # Every name and prefix checks out before RomM is asked for anything.
    (let [games* (seq [g :in games] (let [m (shortcut-here! g)] [m (local-saves m)]))
          entries (steam/romm-entries (map |(get-in $0 [0 :name]) games*))]
      (each [mine local] games*
        (steam/romm-saves (mine :name) local (entries (mine :name)) :direction :download :force? force?)
        (echo :check (fmt "%s ← %s" (mine :name) host))))

    (or gamenative? (retroid/android? host))
    (let [remotes (retroid/games host)]
      (each game games
        (pull-game-android host game remotes force? direct?)))

    # Likewise, and HOST's shortcuts come first: a game it hasn't got is the
    # likelier typo.
    (let [remotes (steam/remote-shortcuts host)
          games* (seq [g :in games] (resolve host g remotes))
          entries (if direct? {} (steam/romm-entries (map |(get-in $0 [:mine :name]) games*)))]
      (each game games*
        (pull-game host game force? (entries (get-in game [:mine :name])))))))
