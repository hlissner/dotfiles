#!/usr/bin/env janet
# List non-Steam shortcuts, here or on HOST.
#
# SYNOPSIS:
#   hey .steam ls [HOST] [-n]
#
# DESCRIPTION:
#   For lookups when I want to `hey .steam {push,pull}` from another steam
#   device. Displays one shortcut per row: name, appid, exe, whether its Proton
#   prefix exists (pfx), and which custom art it has (g=grid h=hero l=logo
#   b=banner i=icon; local only). HOST's list comes straight from its
#   shortcuts.vdf.
#
# OPTIONS:
#   -n, --names
#     Names only, one per line. What the completion reads.
#
# ARGUMENTS:
#   1 HOST @ssh-host

(use hey)
(use sh)
(import hey/steam)

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

(defmain [_ host &opts names? [-n --names]]
  (def rows (if host (remote-rows host) (local-rows)))
  (if names?
    (each r rows (print (r :name)))
    (let [width (max 4 ;(map |(length ($0 :name)) rows))
          pad |(string $0 (string/repeat " " (- $1 (length $0))))]
      (each r rows
        (printf "%s  %10d  %s  %s %s"
                (pad (r :name) width) (r :appid) (if (r :pfx) "pfx" "   ")
                (pad (r :art) 4) (r :exe))))))
