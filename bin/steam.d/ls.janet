#!/usr/bin/env janet
# List non-Steam shortcuts on HOST (or here).
#
# SYNOPSIS:
#   hey .steam ls [HOST] [-n] [-g]
#
# DESCRIPTION:
#   Use this to look up shortcuts before you `hey .steam {push,pull,rm}` them.
#   Displays one shortcut per row: name, appid, exe, whether its Proton prefix
#   exists (pfx), and which custom art it has (g=grid h=hero l=logo b=banner
#   i=icon; local only). HOST's list comes straight from shortcuts.vdf. `romm`
#   is a special target that lists the Windows ROMs push installs from.
#
#   Android HOSTs (GameNative) lists the game folders in GameNative/CustomGames
#   on its SD card instead: name, no appid, whether anything is waiting in its
#   Download/GameNative/GAME/ mailbox (mbx), and the exe.
#
# OPTIONS:
#   -n, --names
#     Names only, one per line. What the completion reads.
#   -g, --gamenative
#     Treat HOST as an Android/GameNative device without asking it.
#
# ARGUMENTS:
#   1 HOST @ssh-host

(use hey)
(use sh)
(import hey/steam)
(import hey/romm)
(import hey/romm/retroid)

(def- art-letters {0 "g" 1 "h" 2 "l" 3 "b" 4 "i"})

(defn- local-rows []
  (def dir (steam/steam-dir))
  (def uid (steam/user-id dir))
  (seq [s :in (steam/shortcuts (slurp (steam/shortcuts-file dir uid)))]
    {:name (s :name) :appid (s :appid) :exe (s :exe-path)
     :pfx (path/directory? (steam/prefix-dir dir (s :appid)))
     :art (string/join (map |(art-letters ($0 :type))
                            (steam/artwork dir uid (s :appid) (s :icon))))}))

(defn- remote-rows [host]
  (def shortcuts (steam/remote-shortcuts host))
  # One trip for every prefix, not one per shortcut.
  (def out @"")
  ($? ssh ,host
      ,(string "for a in " (string/join (map |(string ($0 :appid)) shortcuts) " ")
               "; do test -d " steam/remote-steam-dir "/steamapps/compatdata/$a/pfx && echo $a; done")
      > ,out > [stderr :null])
  (def present (string/split "\n" (string out)))
  (seq [s :in shortcuts]
    {:name (s :name) :appid (s :appid) :exe (s :exe-path)
     :pfx (truthy? (index-of (string (s :appid)) present))
     :art ""}))

(defn- android-rows [host]
  (seq [g :in (retroid/games host)]
    {:name (g :name) :appid "-" :exe (g :exe) :pfx (g :mbx) :pfx-label "mbx" :art ""}))

(defn- romm-rows []
  (seq [r :in (romm/roms)]
    {:name (r :name) :appid (r :id) :exe (r :file)
     :pfx (steam/archive? (r :file)) :pfx-label "arc" :art ""}))

(defmain [_ host &opts names? [-n --names] gamenative? [-g --gamenative]]
  (def rows
    (cond
      (nil? host) (local-rows)
      (= host romm/pseudo-host) (romm-rows)
      (or gamenative? (retroid/android? host)) (android-rows host)
      (remote-rows host)))
  (if names?
    (each r rows (print (r :name)))
    (let [width (max 4 ;(map |(length ($0 :name)) rows))
          pad |(string $0 (string/repeat " " (- $1 (length $0))))]
      (each r rows
        (printf "%s  %10s  %s  %s %s"
                (pad (r :name) width) (string (r :appid))
                (if (r :pfx) (get r :pfx-label "pfx") "   ")
                (pad (r :art) 4) (r :exe))))))
