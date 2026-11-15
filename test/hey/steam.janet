#!/usr/bin/env janet
# Regression tests for lib/hey/steam.janet and bin/steam.d/*.
#
# ssh and rsync are stubs (steam.d/bin/*): rsync says what it was asked, ssh
# runs the remote command in a fake $HOME and answers the CEF client with
# whatever the suite says. What's pinned is the binary VDF reader, how a game
# moves house, and that push/pull send the right dir to the right prefix --
# the remote appid, never mine -- without ever deleting a save. An Android
# remote (HEY_STEAM_TEST_ANDROID) is a Retroid running GameNative: games on the
# SD card, saves through its Download/GameNative mailbox, nothing asked of a
# Steam that isn't there.

(use judge)
(use sh)
(import hey)
(import hey/steam)
(import hey/romm/retroid)
(import hey/romm)
(import spork/json)
(import spork/base64)

(def- bin (hey/path :home "bin/hey"))
(def- stubs (hey/path :test "hey/steam.d/bin"))
(def- home (hey/path :test "hey/steam.d/home"))
(def- steam-dir (string home "/.local/share/Steam"))
(def- uid "14957857")

# The vdf is this machine's, so the shape is whatever Steam writes today.
(def- local-shortcuts (steam/shortcuts (slurp (steam/shortcuts-file steam-dir uid))))
(def- pragmata (steam/find-shortcut local-shortcuts "Pragmata"))

## Scratch: a fake remote $HOME, per run.

(def- runtime
  (let [dir (hey/path :runtime "test.d" (string "steam-" (os/getpid)))]
    (os/mkdir (hey/path :runtime))
    (os/mkdir (hey/path :runtime "test.d"))
    dir))
(def- log (string runtime "/log"))
(def- cache (string runtime "/cache"))   # where push unpacks RomM's archives; reset wipes it
(def- unpacked (string cache "/hey/romm/win"))

## RomM: a canned server (steam.d/bin/{curl,rbw}, steam.d/romm/*.json) whose one
## proton save for Pragmata is the real helper's packing of a two-file user dir.

(def- romm-dir (string runtime "-romm"))   # reset wipes runtime; this stays
(def- library (string runtime "-library"))  # the NAS share, when a test mounts it

(defn- plant-user-dir
  "A Windows user dir under DIR: two saves, a cache file the excludes drop."
  [dir]
  ($ mkdir -p ,(string dir "/Saved Games") ,(string dir "/AppData/Roaming/Game") ,(string dir "/AppData/Local/Temp"))
  (spit (string dir "/Saved Games/slot1.sav") "slot one")
  (spit (string dir "/AppData/Roaming/Game/settings.ini") "[video]\nvsync=1\n")
  (spit (string dir "/AppData/Local/Temp/scratch") "junk")
  ($ touch -d "2026-11-09 12:00:00 UTC" ,(string dir "/Saved Games/slot1.sav") ,(string dir "/AppData/Roaming/Game/settings.ini")))

(defn- pack-rom
  ``ROM-ID's archive in the canned RomM: FILES, {path contents}, as the library
  holds it. A zip unless EXT says 7z.``
  [rom-id files &opt ext]
  (default ext "zip")
  (def out (string romm-dir "/rom-" rom-id "." ext))
  (if (= ext "7z")
    (let [tree (string romm-dir "/rom-" rom-id ".d")]
      (eachp [n c] files
        ($ mkdir -p ,(hey/path/dirname (string tree "/" n)))
        (spit (string tree "/" n) c))
      ($ "7zz" a -bso0 -bsp0 ,out ,(string tree "/."))
      ($ rm -rf ,tree))
    (let [script "import json,sys,zipfile\nz=zipfile.ZipFile(sys.argv[1],'w')\nfor n,c in json.load(sys.stdin).items(): z.writestr(n,c)\nz.close()"]
      ($ python3 -I -c ,script ,out < ,(buffer (json/encode files))))))

(def- planted
  (do ($? rm -rf ,romm-dir)
      ($ mkdir -p ,romm-dir)
      # Pragmata's zip wraps its folder and holds a second exe under Bin/,
      # Fuga's is a 7z that wraps too, Hollow Knight's is flat with one exe
      # and no shortcut here to speak for it, Quake's is flat with two and none.
      (pack-rom 7231 {"PRAGMATA/PRAGMATA.exe" "mz" "PRAGMATA/data.pak" "pak" "PRAGMATA/Bin/Tool.exe" "mz"})
      (pack-rom 7232 {"Fuga - Melodies of Steel/TANK.exe" "mz" "Fuga - Melodies of Steel/tank.dat" "dat"} "7z")
      (pack-rom 7234 {"hollow_knight.exe" "mz" "hollow_knight_Data/level0" "lvl"})
      (pack-rom 7235 {"quake.exe" "mz" "glquake.exe" "mz" "id1/pak0.pak" "pak"})
      (plant-user-dir (string romm-dir "/steamuser"))
      (def reply (steam/sync-saves {:dir (string romm-dir "/steamuser") :exclude steam/save-excludes
                                    :direction "upload" :latest nil}))
      (spit (string romm-dir "/save.zip") (base64/decode (reply :zip)))
      reply))

(defn- write-vdf
  "The writer the lib doesn't have: TBL as binary VDF, keys in sorted order."
  [tbl &opt buf]
  (default buf @"")
  (each k (sort (keys tbl))
    (def v (tbl k))
    (cond
      (dictionary? v) (do (buffer/push buf "\0" k "\0") (write-vdf v buf))
      (string? v) (buffer/push buf "\x01" k "\0" v "\0")
      (number? v) (buffer/push buf "\x02" k "\0"
                               # Arithmetic: band chokes past int32.
                               (string/from-bytes (% v 0x100)
                                                  (% (div v 0x100) 0x100)
                                                  (% (div v 0x10000) 0x100)
                                                  (% (div v 0x1000000) 0x100)))
      (errorf "write-vdf: can't write %q" v)))
  (buffer/push buf "\x08"))

(defn- shortcut-entry [appid name exe start-dir]
  @{"appid" appid "AppName" name "Exe" (string `"` exe `"`) "StartDir" start-dir
    "LaunchOptions" "" "icon" "" "tags" @{}})

(defn- reset
  ``A fresh fake remote: its shortcuts.vdf has Pragmata (4242, with a prefix),
  Fuga (777, without), Trails (555, without) and Konsole (999, a shortcut to a
  system binary, as the Deck has), and nothing else.``
  []
  ($? rm -rf ,runtime)
  (def remote-steam (string runtime "/.local/share/Steam"))
  ($ mkdir -p ,(string remote-steam "/userdata/" uid "/config")
     ,(string remote-steam "/steamapps/compatdata/4242/pfx/drive_c/users/steamuser")
     ,(string runtime "/.steam"))
  # SteamOS has the symlink, and the debugger marker goes through it. It's
  # already on, as it would be after the first push.
  ($ ln -s ../.local/share/Steam ,(string runtime "/.steam/steam"))
  (spit (string remote-steam "/.cef-enable-remote-debugging") "")
  (spit (string remote-steam "/userdata/" uid "/config/shortcuts.vdf")
        (write-vdf @{"shortcuts"
                     @{"0" (shortcut-entry 4242 "Pragmata" (string runtime "/Games/PRAGMATA/PRAGMATA.exe") (string runtime "/Games/PRAGMATA"))
                       "1" (shortcut-entry 777 "Fuga: Melodies of Steel" (string runtime "/Games/Fuga - Melodies of Steel/TANK.exe") (string runtime "/Games/Fuga - Melodies of Steel"))
                       "2" (shortcut-entry 555 "Trails in the Sky: Chapter 1" (string runtime "/Games/Trails in the Sky 1st Chapter/sora_1st.exe") (string runtime "/Games/Trails in the Sky 1st Chapter"))
                       "3" (shortcut-entry 999 "Konsole" "/usr/bin/konsole" "/usr/bin")}}))
  (spit log ""))

(defn- hey-steam*
  "Run `hey .steam ARGS` after SETUP; [exit-code stdout stderr log-lines]."
  [setup & args]
  (setup)
  (def out @"")
  (def err @"")
  (def code
    (hey/with-envvars ["HOME" home
                       "XDG_BIN_HOME" stubs
                       "XDG_CACHE_HOME" cache
                       "HEY_STEAM_TEST_REMOTE" runtime
                       "HEY_STEAM_TEST_ROMM" romm-dir
                       "ROMM_LIBRARY" library
                       "HEY_STEAM_TEST_LOG" log]
      (first (run ,bin .steam ,;args > ,out > [stderr err]))))
  [code (string out) (string err)
   (filter |(not (empty? $0)) (string/split "\n" (string (slurp log))))])

(defn- hey-steam
  "Run `hey .steam ARGS` against a fresh fake remote."
  [& args]
  (hey-steam* reset ;args))

(def- sd (string runtime "/mnt/storage/1234-5678"))
(def- games-dir (string sd "/GameNative/CustomGames"))
(def- mailbox (string runtime "/mnt/storage/emulated/0/Download/GameNative"))

(defn- reset-android
  ``A fresh fake Retroid: an SD card holding GameNative/CustomGames with
  Pragmata (whose saves sit in the mailbox), Fuga (not), Hollow Knight (in the
  mailbox; no shortcut here) and Trails (in the mailbox; a shortcut here with
  no prefix, and RomM hasn't got it), Termux's shared storage link, and no
  Steam anywhere.``
  []
  ($? rm -rf ,runtime)
  ($ mkdir -p ,(string games-dir "/Pragmata/Bin") ,(string games-dir "/Fuga - Melodies of Steel")
     ,(string games-dir "/Hollow Knight") ,(string games-dir "/Trails in the Sky - Chapter 1")
     ,(string games-dir "/Not a game") ,(string runtime "/mnt/storage/emulated/0") ,(string runtime "/mnt/storage/self")
     ,(string mailbox "/Pragmata/AppData") ,(string mailbox "/Hollow Knight/AppData")
     ,(string mailbox "/Trails in the Sky - Chapter 1/AppData")
     # An empty mailbox is no mailbox.
     ,(string mailbox "/Fuga - Melodies of Steel"))
  (spit (string games-dir "/Pragmata/Bin/PRAGMATA.exe") "")
  (spit (string games-dir "/Fuga - Melodies of Steel/TANK.exe") "")
  (spit (string games-dir "/Hollow Knight/hollow_knight.exe") "")
  (spit (string games-dir "/Trails in the Sky - Chapter 1/sora_1st.exe") "")
  (spit log ""))

(defn- hey-android*
  "Run `hey .steam ARGS` after SETUP, against a Retroid."
  [setup & args]
  (hey/with-envvars ["HEY_STEAM_TEST_ANDROID" "1"]
    (hey-steam* setup ;args)))

(defn- hey-android
  "Run `hey .steam ARGS` against a fresh fake Retroid."
  [& args]
  (hey-android* reset-android ;args))

(defn- has? [needle s] (truthy? (string/find needle s)))
(defn- words [line] (string/split " " line))
(defn- rsyncs [lines] (filter |(string/has-prefix? "rsync " $0) lines))
(defn- verbs [lines] (map |(string/join (take 2 (words $0)) " ") lines))
(defn- remote-calls
  "LINES without the RomM side (rbw, curl, the local python)."
  [lines]
  (filter |(or (string/has-prefix? "ssh " $0) (string/has-prefix? "rsync " $0)) lines))
(defn- requests
  "Each request the saves helper got, decoded, in order."
  []
  (def f (string log ".romm"))
  (if (os/stat f)
    (map |(json/decode $0 true true) (filter |(not (empty? $0)) (string/split "\n" (string (slurp f)))))
    @[]))
(defn- curl-log [] (if (os/stat (string log ".curl")) (string (slurp (string log ".curl"))) ""))

## The VDF reader

(deftest vdf/round-trip
  (def tbl @{"shortcuts" @{"0" @{"appid" 3652376892 "AppName" "Prägmata" "Exe" `"/g/x.exe"` "tags" @{}}
                           "1" @{"appid" 1 "AppName" "b"}}})
  (test (deep= (steam/read-vdf (write-vdf tbl)) tbl) true))

(deftest vdf/uint32-stays-unsigned
  # The top bit is set on every shortcut appid; a bor would come back negative.
  (test (get-in (steam/read-vdf (write-vdf @{"n" 3652376892})) ["n"]) 3652376892))

(deftest vdf/rejects-junk
  (test-error (steam/read-vdf (string (write-vdf @{"a" "b"}) "x")) "vdf: 1 bytes of trailing data")
  (test-error (steam/read-vdf "\x01a\0b\0") "vdf: map never closed")
  (test-error (steam/read-vdf "\x07a\0") "vdf: unknown node type 0x07 at 0"))

(deftest vdf/real-file
  (test (map |($0 :name) local-shortcuts)
        @["Pragmata" "Trails in the Sky: Chapter 1" "ES-DE" "Fuga: Melodies of Steel"])
  (test (map |($0 :appid) local-shortcuts) @[3652376892 3586770650 3054193443 2894349286])
  (test (pragmata :exe) "\"/media/data/games/PRAGMATA/PRAGMATA.exe\"")
  (test (pragmata :exe-path) "/media/data/games/PRAGMATA/PRAGMATA.exe")
  (test (string/has-prefix? "gamemoderun" (pragmata :launch-options)) true))

(deftest vdf/lowercase-keys
  # Older Steams wrote the keys in lowercase, and still read them.
  (def bytes (write-vdf @{"shortcuts" @{"0" @{"appid" 9 "appname" "Old" "exe" `"/o/o.exe"` "startdir" "/o"}}}))
  (test (first (steam/shortcuts bytes)) {:appid 9 :exe "\"/o/o.exe\"" :exe-path "/o/o.exe" :icon "" :launch-options "" :name "Old" :start-dir "/o"}))

## Pure helpers

(deftest find-shortcut
  (test (get (steam/find-shortcut local-shortcuts "pragmata") :appid) 3652376892)
  (test (get (steam/find-shortcut local-shortcuts "Fuga: Melodies of Steel") :appid) 2894349286)
  (test (steam/find-shortcut local-shortcuts "Fuga") nil))

(deftest relocate
  (test (steam/relocate pragmata "/home/deck/Games")
        {:dir "/home/deck/Games/PRAGMATA" :exe "/home/deck/Games/PRAGMATA/PRAGMATA.exe"})
  # Trails' StartDir has no trailing slash; Pragmata's does.
  (test (steam/relocate (steam/find-shortcut local-shortcuts "Trails in the Sky: Chapter 1") "/home/deck/sd/games")
        {:dir "/home/deck/sd/games/Trails in the Sky 1st Chapter"
         :exe "/home/deck/sd/games/Trails in the Sky 1st Chapter/sora_1st.exe"})
  # es-de is a command on $PATH with StartDir ./: nothing to move.
  (test-error (steam/relocate (steam/find-shortcut local-shortcuts "ES-DE") "/home/deck/Games")
              "ES-DE's exe (es-de) isn't inside its start dir (./); nothing to copy")
  (test-error (steam/relocate {:name "x" :exe-path "/elsewhere/x.exe" :start-dir "/games/x"} "/h/G")
              "x's exe (/elsewhere/x.exe) isn't inside its start dir (/games/x); nothing to copy"))

(deftest artwork
  # The fixture has p.png, .jpg, _hero.jpg and _logo.png; ES-DE's icon is a
  # theme name, not a file.
  (test (map |[($0 :type) ($0 :ext)] (steam/artwork steam-dir uid 3652376892 "org.es_de.frontend"))
        @[[0 "png"] [1 "jpg"] [2 "png"] [3 "jpg"]])
  (test (steam/artwork steam-dir uid 2894349286) @[])
  # A loose icon file stands in for a missing _icon.
  (test (map |[($0 :type) ($0 :ext)]
             (steam/artwork steam-dir uid 2894349286 (string steam-dir "/userdata/" uid "/config/grid/3652376892p.png")))
        @[[4 "png"]])
  (test (steam/encode-art (steam/artwork steam-dir uid 3652376892))
        @{"0" {:data "UE5H" :ext "png"} "1" {:data "SlBH" :ext "jpg"} "2" {:data "UE5H" :ext "png"} "3" {:data "SlBH" :ext "jpg"}}))

(deftest register-js
  (def js (steam/register-js {:name "Fuga: Melodies of Steel" :exe "/home/deck/Games/F/TANK.exe"
                              :start-dir "/home/deck/Games/F" :compat "proton_experimental"
                              :art {"0" {:data "UE5H" :ext "png"}}}))
  (test (has? `const name = "Fuga: Melodies of Steel";` js) true)
  (test (has? `const exe = "/home/deck/Games/F/TANK.exe";` js) true)
  (test (has? `const launchOptions = "";` js) true)
  (test (has? `const compat = "proton_experimental";` js) true)
  (test (has? `const art = {"0":{"data":"UE5H","ext":"png"}};` js) true)
  # By name, so a second push updates rather than duplicates.
  (test (has? "a.app_type === 1073741824 && a.display_name === name" js) true)
  # ...and reports the old exe unquoted, so push can compare it to the one it'd set.
  (test (has? `d.strShortcutExe.replace(/^"(.*)"$/, '$1')` js) true)
  (test (has? "SpecifyCompatTool(appid, compat)" js) true)
  (def bare (steam/register-js {:name "x" :exe "/x" :start-dir "/" :launch-options "a %command%" :compat ""}))
  (test (has? `const launchOptions = "a %command%";` bare) true)
  (test (has? `const compat = "";` bare) true)
  (test (has? `const art = {};` bare) true))

(deftest cdp-py
  # It only ever runs on the other machine, so at least make sure it parses...
  (test ($? python3 -I -c "import ast, sys; ast.parse(sys.stdin.read())" < ,(buffer steam/cdp-py)) true)
  # ...and survives the trip through the remote shell as one argument.
  (def out @"")
  ($ sh -c ,(string "printf %s " (hey/shell-quote steam/cdp-py)) > ,out)
  (test (= (string out) steam/cdp-py) true))

## Saves through RomM

(deftest romm/sync-py
  (test ($? python3 -I -c "import ast, sys; ast.parse(sys.stdin.read())" < ,(buffer steam/sync-py)) true)
  (test (string/has-prefix? "# hey:romm-saves\n" steam/sync-py) true)
  (def out @"")
  ($ sh -c ,(string "printf %s " (hey/shell-quote steam/sync-py)) > ,out)
  (test (= (string out) steam/sync-py) true))

(deftest romm/pack
  # The fixture's packing: two files, the cache dropped, newest mtime on
  # record, and RomM's hash of it -- md5 over "name:md5(entry)" lines.
  (test (planted :action) "upload")
  (test (planted :files) 2)
  (test (planted :mtime) 1794225600)
  (test (planted :hash) "6eb672117ad4f1d7d840a031bcf86115")
  (def names @"")
  ($ python3 -I -c "import sys, zipfile, json; z = zipfile.ZipFile(sys.argv[1]); print(json.dumps([z.namelist(), z.comment.decode()]))"
     ,(string romm-dir "/save.zip") > ,names)
  (test (json/decode names) @[@["AppData/Roaming/Game/settings.ini" "Saved Games/slot1.sav"] "{\"mtime\": 1794225600.0, \"files\": 2}"])
  # Nothing there: nothing to send, not an empty save.
  (def empty (string runtime "-romm/empty")) ($ mkdir -p ,empty)
  (test (steam/sync-saves {:dir empty :direction "upload" :latest nil}) @{:action "skip" :files 0 :reason "empty"})
  (test (steam/sync-saves {:dir (string empty "/nope") :direction "upload" :latest nil}) @{:action "skip" :reason "no-dir"}))

(deftest romm/round-trip
  (def zip (slurp (string romm-dir "/save.zip")))
  (def dir (string runtime "-romm/deck/steamuser"))
  ($? rm -rf ,(string runtime "-romm/deck"))
  (def server {:content_hash (planted :hash) :updated_at "2026-11-10T00:00:00Z"})
  (defn sync [& more]
    (steam/sync-saves (merge {:dir dir :exclude steam/save-excludes :latest server :server_zip (base64/encode (string zip))} ;more)))
  # No prefix there yet: only --seed makes one.
  (test (sync {:direction "download"}) @{:action "skip" :reason "no-dir"})
  (test (sync {:direction "download" :mkpath true :dry_run true}) @{:action "download" :files 0 :mtime 0 :server_mtime 1794225600})
  (test (os/stat dir) nil)
  (test (sync {:direction "download" :mkpath true}) @{:action "download" :files 2 :mtime 0 :server_mtime 1794225600})
  (test (string (slurp (string dir "/Saved Games/slot1.sav"))) "slot one")
  (test (os/stat (string dir "/AppData/Roaming/Game/settings.ini") :modified) 1794225600)
  # Both sides the same now: a no-op either way, whatever the clocks say.
  (test (sync {:direction "download"}) @{:action "noop" :files 2 :hash "6eb672117ad4f1d7d840a031bcf86115" :mtime 1794225600})
  (test (sync {:direction "upload" :force true}) @{:action "noop" :files 2 :hash "6eb672117ad4f1d7d840a031bcf86115" :mtime 1794225600})
  # Played since: this side is newer, so it goes up and RomM's doesn't come down...
  (spit (string dir "/Saved Games/slot2.sav") "slot two")
  ($ touch -d "2026-11-12 09:00:00 UTC" ,(string dir "/Saved Games/slot2.sav"))
  (def up (sync {:direction "upload" :latest {:content_hash "stale" :updated_at "2026-11-10T00:00:00Z"}}))
  (test (up :action) "upload")
  (test [(up :files) (up :mtime) (up :server_mtime)] [3 1794474000 1794225600])
  (test (up :hash) "f3dd56848820995cf10aee342c652644")
  (test (steam/sync-saves {:dir dir :direction "upload" :latest nil :dry_run true})
        @{:action "upload" :files 3 :hash "f3dd56848820995cf10aee342c652644" :mtime 1794474000})
  (test (sync {:direction "download" :latest {:content_hash "stale" :updated_at "2026-11-12T10:00:00Z"}})
        @{:action "skip" :reason "side-newer" :files 3 :hash "f3dd56848820995cf10aee342c652644" :mtime 1794474000 :server_mtime 1794225600})
  # ...unless forced, which brings RomM's files back without deleting the new one.
  (test (get (sync {:direction "download" :force true :latest {:content_hash "stale" :updated_at "2026-11-10T00:00:00Z"}}) :action) "download")
  (test (os/stat (string dir "/Saved Games/slot2.sav") :mode) :file)
  # RomM newer than this side: it comes down, and this side's older files don't go up.
  (def older (string runtime "-romm/older/steamuser"))
  (plant-user-dir older)
  ($ touch -d "2026-11-01 00:00:00 UTC" ,(string older "/Saved Games/slot1.sav") ,(string older "/AppData/Roaming/Game/settings.ini"))
  (spit (string older "/Saved Games/slot1.sav") "stale one")
  ($ touch -d "2026-11-01 00:00:00 UTC" ,(string older "/Saved Games/slot1.sav"))
  (def down (steam/sync-saves {:dir older :exclude steam/save-excludes :direction "upload" :latest server :server_zip (base64/encode (string zip))}))
  (test [(down :action) (down :reason) (down :mtime) (down :server_mtime)] ["skip" "server-newer" 1793491200 1794225600])
  (test (get (steam/sync-saves {:dir older :exclude steam/save-excludes :direction "download" :latest server :server_zip (base64/encode (string zip))}) :action) "download")
  (test (string (slurp (string older "/Saved Games/slot1.sav"))) "slot one")
  # A zip off the network is treated as such.
  (def evil @"")
  ($ python3 -I -c "import sys, zipfile, io, base64; b = io.BytesIO(); z = zipfile.ZipFile(b, 'w'); z.writestr('../x', 'no'); z.close(); print(base64.b64encode(b.getvalue()).decode())" > ,evil)
  (def err @"")
  (test ($? python3 -I -c ,steam/sync-py
            < ,(buffer (json/encode {:dir dir :direction "download" :force true :latest server :server_zip (string/trim (string evil))}))
            > :null > [stderr err])
        false)
  (test (string/trim (string err)) "refusing zip entry '../x'"))

(deftest romm/lookups
  # The lib against the canned server: the key off rbw's custom field, the
  # ROM by its file name (tags and the colon's spelling aside), the newest
  # proton save.
  (hey/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH")) "HEY_STEAM_TEST_LOG" log "HEY_STEAM_TEST_ROMM" romm-dir]
    (os/mkdir runtime)
    (spit log "")
    (spit (string log ".curl") "")
    (test (romm/api-key) "rmm_test")
    (test (romm/platform-id) 3)
    (test (romm/find-rom ["Pragmata"] 3) {:id 7231 :name "Pragmata" :title "PRAGMATA" :file "Pragmata.zip"})
    (test (romm/find-rom ["pragmata"] 3) {:id 7231 :name "Pragmata" :title "PRAGMATA" :file "Pragmata.zip"})
    (test (romm/find-rom ["Fuga: Melodies of Steel" "Fuga - Melodies of Steel"] 3)
          {:id 7232 :name "Fuga - Melodies of Steel" :title "Fuga: Melodies of Steel" :file "Fuga - Melodies of Steel (v1.52).7z"})
    (test (romm/find-rom ["Trails in the Sky: Chapter 1" "Trails in the Sky - Chapter 1"] 3) nil)
    (test (romm/latest-save 7231) @{:id 99 :rom_id 7231 :file_name "Pragmata.zip" :slot "proton" :emulator "proton" :content_hash "h99" :updated_at "2026-11-09T13:02:11Z" :file_size_bytes 10})
    (test (romm/latest-save 7232) nil)
    (test (= (string (romm/fetch-save 99)) (string (slurp (string romm-dir "/save.zip")))) true)
    (test (get (romm/upload-save 7231 "Pragmata.zip" "bytes") :id) 100)
    (test (filter |(string/has-prefix? "curl " $0) (string/split "\n" (string/trim (slurp log))))
          @["curl https://romm.home.lissner.net/api/platforms"
            "curl https://romm.home.lissner.net/api/roms?limit=50&platform_ids=3&search_term=Pragmata"
            "curl https://romm.home.lissner.net/api/roms?limit=50&platform_ids=3&search_term=pragmata"
            "curl https://romm.home.lissner.net/api/roms?limit=50&platform_ids=3&search_term=Fuga"
            "curl https://romm.home.lissner.net/api/roms?limit=50&platform_ids=3&search_term=Trails%20in%20the%20Sky"
            "curl https://romm.home.lissner.net/api/saves?rom_id=7231"
            "curl https://romm.home.lissner.net/api/saves?rom_id=7232"
            "curl https://romm.home.lissner.net/api/saves/99/content"
            "curl https://romm.home.lissner.net/api/saves?autocleanup=true&autocleanup_limit=10&emulator=proton&rom_id=7231&slot=proton"])
    # The key is memoized: rbw was asked once.
    (test (filter |(string/has-prefix? "rbw " $0) (string/split "\n" (string/trim (slurp log)))) @["rbw unlocked" "rbw get --raw romm.home.lissner.net"])
    (test (= (slurp (string log ".curl")) "") false)))

## The commands

(deftest ls
  (def [code out _ lines] (hey-steam "ls"))
  (test code 0)
  (test (string/split "\n" (string/trim out))
        @["Pragmata                      3652376892  pfx  ghlb /media/data/games/PRAGMATA/PRAGMATA.exe"
          "Trails in the Sky: Chapter 1  3586770650            /media/data/games/Trails in the Sky 1st Chapter/sora_1st.exe"
          "ES-DE                         3054193443            es-de"
          "Fuga: Melodies of Steel       2894349286  pfx       /media/data/games/Fuga - Melodies of Steel/TANK.exe"])
  (test lines @[])
  (test (get (hey-steam "ls" "-n") 1) "Pragmata\nTrails in the Sky: Chapter 1\nES-DE\nFuga: Melodies of Steel\n"))

(deftest ls/romm
  (def [code out _ lines] (hey-steam "ls" "romm"))
  (test code 0)
  (test (remote-calls lines) @[])
  (test (string/split "\n" (string/trim out))
        @["Pragmata                          7231  arc       Pragmata.zip"
          "Fuga - Melodies of Steel          7232  arc       Fuga - Melodies of Steel (v1.52).7z"
          "Fuga - Melodies of Steel 2        7233            Fuga - Melodies of Steel 2.iso"
          "Hollow Knight                     7234  arc       Hollow Knight.zip"
          "Quake                             7235  arc       Quake.zip"])
  (test (get (hey-steam "ls" "-n" "romm") 1) "Pragmata\nFuga - Melodies of Steel\nFuga - Melodies of Steel 2\nHollow Knight\nQuake\n"))

(deftest ls/remote
  (def [code out _ lines] (hey-steam "ls" "deck.lan"))
  (test code 0)
  (test (map |(take 2 (words $0)) (string/split "\n" (string/trim out)))
        @[["Pragmata" ""] ["Fuga:" "Melodies"] ["Trails" "in"] ["Konsole" ""]])
  (test (has? "4242  pfx" out) true)
  (test (has? "777       " out) true)
  (test (get (hey-steam "ls" "-n" "deck.lan") 1) "Pragmata\nFuga: Melodies of Steel\nTrails in the Sky: Chapter 1\nKonsole\n"))

(deftest push
  (def [code out err lines] (hey-steam "push" "deck.lan" "Pragmata"))
  (test code 0)
  # uname; $HOME, the debugger marker, the library list; mkdir + the game; register; the saves helper on the Deck.
  (test (verbs (remote-calls lines))
        @["ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "rsync -rltDP" "ssh deck.lan" "ssh deck.lan"])
  # RomM's side, all of it before $HOME is even asked for: the key, the win
  # platform, the ROM, its zip, its saves, the newest one's bytes. Then, after
  # the game: the helper here, the upload, the helper there.
  (test (verbs (filter |(not (string/has-prefix? "ssh " $0)) lines))
        @["rbw unlocked" "rbw get"
          "curl https://romm.home.lissner.net/api/platforms"
          "curl https://romm.home.lissner.net/api/roms?limit=50&platform_ids=3&search_term=Pragmata"
          "curl https://romm.home.lissner.net/api/roms/7231/content/Pragmata.zip"
          "curl https://romm.home.lissner.net/api/saves?rom_id=7231"
          "curl https://romm.home.lissner.net/api/saves/99/content"
          "rsync -rltDP" "python3 -I"
          "curl https://romm.home.lissner.net/api/saves?autocleanup=true&autocleanup_limit=10&emulator=proton&rom_id=7231&slot=proton"
          "python3 -I"])
  # The zip's one folder is the game dir, and its exe is the one my shortcut
  # runs, Bin/Tool.exe notwithstanding; the zip itself is gone.
  (test (= (first (rsyncs lines)) (string "rsync -rltDP " unpacked "/Pragmata/ deck.lan:" runtime "/Games/Pragmata/")) true)
  (test (os/stat (string unpacked "/Pragmata/PRAGMATA.exe") :mode) :file)
  (test (os/stat (string unpacked "/Pragmata/PRAGMATA")) nil)
  (test (os/stat (string unpacked "/Pragmata.zip")) nil)
  # No rsync of the saves: up from my prefix, down into the one Steam on the Deck handed out.
  (test (length (rsyncs lines)) 1)
  (def [up down] (requests))
  (test (up :direction) "upload")
  (test (= (up :dir) (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser")) true)
  (test (up :exclude)
        @["AppData/Local/Temp" "AppData/Local/dxvk" "AppData/Local/Microsoft" "AppData/Local/UnrealEngine"
          "AppData/Local/openvr" "AppData/Local/D3DSCache" "AppData/Local/NVIDIA" "AppData/Local/AMD"
          "AppData/Local/CrashDumps"])
  (test (up :latest) @{:content_hash "h99" :updated_at "2026-11-09T13:02:11Z"})
  (test (= (up :server_zip) (base64/encode (string (slurp (string romm-dir "/save.zip"))))) true)
  (test [(up :force) (up :mkpath) (up :dry_run)] [false false false])
  (test (down :direction) "download")
  (test (down :dir) ".local/share/Steam/steamapps/compatdata/4242/pfx/drive_c/users/steamuser")
  # The record and bytes the upload just made, not a second fetch.
  (test (down :latest) @{:content_hash "h100" :updated_at "2026-11-10T00:00:00Z"})
  (test (= (down :server_zip) (base64/encode (string (slurp (string romm-dir "/save.zip"))))) true)
  (test [(down :force) (down :mkpath)] [false false])
  # The key rode curl's stdin and nothing else.
  (test (has? "header = \"Authorization: Bearer rmm_test\"" (curl-log)) true)
  (test (has? ";filename=Pragmata.zip;type=application/zip" (curl-log)) true)
  (test (has? "rmm_test" (string/join lines "\n")) false)
  (test (has? "Pragmata: here → RomM (2 files, save 100)" out) true)
  (test (has? "Pragmata: RomM → deck.lan (2 files)" out) true)
  # The game dir landed before anything was registered.
  (test (truthy? (index-of (string "ssh deck.lan mkdir -p '" runtime "/Games/Pragmata'") lines)) true)
  (test (os/stat (string runtime "/Games/Pragmata") :mode) :directory)
  # What Steam was told.
  (def js (string (slurp (string log ".js"))))
  (test (has? `const name = "Pragmata";` js) true)
  (test (has? (string `const exe = "` runtime `/Games/Pragmata/PRAGMATA.exe";`) js) true)
  (test (has? (string `const startDir = "` runtime `/Games/Pragmata";`) js) true)
  (test (has? `const launchOptions = "";` js) true)
  (test (has? `const compat = "proton_experimental";` js) true)
  (test (has? `"ext":"png"` js) true)
  (test (has? "Pragmata: added on deck.lan as 4242" out) true)
  (test (has? "Pragmata → deck.lan (4242)" out) true))

(deftest push/flags
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "pragmata" "-c" "GE-Proton" "-l" "x %command%" "--no-art" "--force"))
  (test code 0)
  (test (map |($0 :force) (requests)) @[true true])
  (def js (string (slurp (string log ".js"))))
  (test (has? `const launchOptions = "x %command%";` js) true)
  (test (has? `const compat = "GE-Proton";` js) true)
  (test (has? `const art = {};` js) true))

(deftest push/default-library
  # The Deck's default library is its SD card: games go in a Games/ there...
  (def libs (fn [& more] (string (json/encode @[@{:path (string runtime "/.local/share/Steam") :default false :mounted true} ;more]))))
  (def [code _ _ lines]
    (hey/with-envvars ["HEY_STEAM_TEST_LIBRARIES" (libs @{:path (string runtime "/sd") :default true :mounted true})]
      (hey-steam "push" "deck.lan" "Pragmata" "--no-saves")))
  (test code 0)
  (test (= (first (rsyncs lines)) (string "rsync -rltDP " unpacked "/Pragmata/ deck.lan:" runtime "/sd/Games/Pragmata/")) true)
  (test (has? (string `const exe = "` runtime `/sd/Games/Pragmata/PRAGMATA.exe";`) (string (slurp (string log ".js")))) true)
  # ...unless it's unplugged.
  (def [_ _ _ lines]
    (hey/with-envvars ["HEY_STEAM_TEST_LIBRARIES" (libs @{:path (string runtime "/sd") :default true :mounted false})]
      (hey-steam "push" "deck.lan" "Pragmata" "--no-saves")))
  (test (= (first (rsyncs lines)) (string "rsync -rltDP " unpacked "/Pragmata/ deck.lan:" runtime "/Games/Pragmata/")) true))

(deftest push/romm-source
  # No shortcut here: RomM's title is the name, the one exe is the exe, there
  # is no art and no prefix to upload, and RomM's save still comes down.
  (def [code out err lines] (hey-steam "push" "deck.lan" "Hollow Knight"))
  (test code 0)
  (test (= (first (rsyncs lines)) (string "rsync -rltDP " unpacked "/Hollow Knight/ deck.lan:" runtime "/Games/Hollow Knight/")) true)
  (test (os/stat (string unpacked "/Hollow Knight/hollow_knight_Data/level0") :mode) :file)
  (def js (string (slurp (string log ".js"))))
  (test (has? `const name = "Hollow Knight";` js) true)
  (test (has? (string `const exe = "` runtime `/Games/Hollow Knight/hollow_knight.exe";`) js) true)
  (test (has? `const art = {};` js) true)
  (test (map |($0 :direction) (requests)) @["download"])
  (test (get (first (requests)) :dir) ".local/share/Steam/steamapps/compatdata/4242/pfx/drive_c/users/steamuser")
  (test (has? "upload saveFile" (curl-log)) false)
  # Unpacked already (a second host, say): no second download.
  (def [code out _ lines] (hey-steam* (fn [] (spit log "")) "push" "deck.lan" "Hollow Knight" "--no-saves"))
  (test code 0)
  (test (filter |(string/find "/content/" $0) lines) @[])
  (test (has? "Hollow Knight: already unpacked in" out) true)
  (test (= (first (rsyncs lines)) (string "rsync -rltDP " unpacked "/Hollow Knight/ deck.lan:" runtime "/Games/Hollow Knight/")) true)
  # The NAS share mounted here: the zip is unpacked off it, RomM never asked
  # for the bytes.
  (def roms (string library "/win/roms"))
  ($ mkdir -p ,roms)
  ($ cp ,(string romm-dir "/rom-7234.zip") ,(string roms "/Hollow Knight.zip"))
  (defer ($? rm -rf ,library)
    (def [code out _ lines] (hey-steam "push" "deck.lan" "Hollow Knight" "--no-saves"))
    (test code 0)
    (test (filter |(string/find "/content/" $0) lines) @[])
    (test (has? (string "Hollow Knight: unpacking " roms "/Hollow Knight.zip") out) true)
    (test (os/stat (string unpacked "/Hollow Knight/hollow_knight_Data/level0") :mode) :file)
    (test (= (first (rsyncs lines)) (string "rsync -rltDP " unpacked "/Hollow Knight/ deck.lan:" runtime "/Games/Hollow Knight/")) true)
    (def [code out _ lines] (hey-steam "push" "-!" "deck.lan" "Hollow Knight" "-e" "hollow_knight.exe"))
    (test code 0)
    (test (has? (string "romm: unpack " roms "/Hollow Knight.zip into") out) true)
    (test (filter |(string/find "/content/" $0) lines) @[]))
  # Two exes and nobody to pick: -e does.
  (def [code _ err lines] (hey-steam "push" "deck.lan" "Quake"))
  (test code 127)
  (test (has? "-e says which: glquake.exe, quake.exe" err) true)
  (test (rsyncs lines) @[])
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "Quake" "-e" "glquake.exe" "--no-saves"))
  (test code 0)
  (test (has? (string `const exe = "` runtime `/Games/Quake/glquake.exe";`) (string (slurp (string log ".js")))) true)
  (test (first (hey-steam "push" "deck.lan" "Quake" "-e" "nope.exe")) 127)
  (test (first (hey-steam "push" "deck.lan" "Quake" "Pragmata" "-e" "glquake.exe")) 127)
  (test (first (hey-steam "push" "deck.lan" "Pragmata" "-e" "PRAGMATA.exe" "--direct")) 127)
  # An .iso is the CD, not a game anything can run.
  (def [code _ err lines] (hey-steam "push" "deck.lan" "Fuga: Melodies of Steel 2"))
  (test code 127)
  (test (has? "install it once and archive the result" err) true)
  (test (filter |(string/find "/content/" $0) lines) @[]))

(deftest push/no-prefix-yet
  # Fuga has never run on the Deck: the helper there finds no dir, and that's
  # the end of it -- the upload stands, and nobody invents a prefix...
  (def [code out err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_ROMM_DOWNLOAD" `{"action":"skip","reason":"no-dir"}`]
      (hey-steam "push" "deck.lan" "Fuga: Melodies of Steel")))
  (test code 0)
  (test (length (rsyncs lines)) 1)
  (test (has? "Launch it there once" err) true)
  # Fuga's file on RomM spells the colon as a dash; no save there yet.
  (test (truthy? (index-of "curl https://romm.home.lissner.net/api/saves?rom_id=7232" lines)) true)
  (test (get (first (requests)) :latest) nil)
  (test (has? "Fuga: Melodies of Steel: here → RomM" out) true)
  (test (get (last (requests)) :mkpath) false)
  (test (get (last (requests)) :dir) ".local/share/Steam/steamapps/compatdata/777/pfx/drive_c/users/steamuser")
  # ...unless told to.
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "Fuga: Melodies of Steel" "--seed"))
  (test code 0)
  (test (get (last (requests)) :mkpath) true))

(deftest push/server-newer
  # Played on the Deck since the last push: RomM's copy wins, and says so.
  (def [code out err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_ROMM_REPLY" `{"action":"skip","reason":"server-newer","files":2}`]
      (hey-steam "push" "deck.lan" "Pragmata")))
  (test code 0)
  (test (has? "RomM's Pragmata.zip is newer than Pragmata's saves; --force" err) true)
  (test (has? "upload saveFile" (curl-log)) false)
  # Nothing changed on either side.
  (test (map |($0 :direction) (requests)) @["upload" "download"])
  (def [code out err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_ROMM_REPLY" `{"action":"noop","files":2}`]
      (hey-steam "push" "deck.lan" "Pragmata")))
  (test code 0)
  (test (has? "Pragmata: here and RomM already match" out) true)
  (test (has? "Pragmata: deck.lan and RomM already match" out) true))

(deftest push/romm-host
  # RomM as HOST: the upload leg only. No ssh, no rsync, no Steam.
  (def [code out err lines] (hey-steam "push" "romm" "Pragmata"))
  (test code 0)
  (test (remote-calls lines) @[])
  (test (map |($0 :direction) (requests)) @["upload"])
  (test (has? "upload saveFile" (curl-log)) true)
  (test (has? "Pragmata → romm" out) true)
  (test (os/stat (string log ".js")) nil)
  (def [code _ err _] (hey-steam "push" "romm" "Pragmata" "-c" "GE-Proton"))
  (test code 0)
  (test (has? "ignored" err) true)
  (test (first (hey-steam "push" "romm" "Pragmata" "--no-saves")) 127)
  (test (first (hey-steam "push" "romm" "Pragmata" "--direct")) 127)
  (test (first (hey-steam "push" "romm" "Nope")) 127))

(deftest push/direct
  # --direct is the old way: rsync the dir, RomM never asked.
  (def [code out err lines] (hey-steam "push" "deck.lan" "Pragmata" "--direct"))
  (test code 0)
  (test (verbs lines)
        @["ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "rsync -rltDP" "ssh deck.lan" "ssh deck.lan" "rsync -rltDzP"])
  (def [game saves] (rsyncs lines))
  # Into the prefix Steam on the Deck handed out, not mine.
  (test (last (words saves)) "deck.lan:.local/share/Steam/steamapps/compatdata/4242/pfx/drive_c/users/steamuser/")
  (test (= (get (words saves) (- (length (words saves)) 2))
           (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser/"))
        true)
  (test (truthy? (index-of "-u" (words saves))) true)
  (test (truthy? (index-of "--delete" (words saves))) false)
  (test (filter |(string/has-prefix? "--exclude=" $0) (words saves))
        @["--exclude=/AppData/Local/Temp/" "--exclude=/AppData/Local/dxvk/"
          "--exclude=/AppData/Local/Microsoft/" "--exclude=/AppData/Local/UnrealEngine/"
          "--exclude=/AppData/Local/openvr/" "--exclude=/AppData/Local/D3DSCache/"
          "--exclude=/AppData/Local/NVIDIA/" "--exclude=/AppData/Local/AMD/"
          "--exclude=/AppData/Local/CrashDumps/"])
  (test (requests) @[])
  (test (curl-log) "")
  # Fuga, never run there: no prefix invented without --seed.
  (def [code _ err lines] (hey-steam "push" "deck.lan" "Fuga: Melodies of Steel" "--direct"))
  (test code 0)
  (test (length (rsyncs lines)) 1)
  (test (has? "Launch it there once" err) true)
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "Fuga: Melodies of Steel" "--direct" "--seed"))
  (test (truthy? (index-of "--mkpath" (words (last (rsyncs lines))))) true)
  (test (string/has-suffix? " deck.lan:.local/share/Steam/steamapps/compatdata/777/pfx/drive_c/users/steamuser/" (last (rsyncs lines))) true)
  (test (truthy? (index-of "-u" (words (last (get (hey-steam "push" "deck.lan" "Pragmata" "--direct" "--force") 3))))) false))

(deftest push/romm-refusals
  # RomM hasn't got Trails: stop before anything leaves.
  (def [code _ err lines] (hey-steam "push" "deck.lan" "Trails in the Sky: Chapter 1"))
  (test code 127)
  (test (has? "Add win/roms/Trails in the Sky: Chapter 1.*" err) true)
  (test (rsyncs lines) @[])
  (test (filter |(string/find "python3" $0) lines) @[])
  # A locked vault, likewise.
  (def [code _ err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_RBW_LOCKED" "1"]
      (hey-steam "push" "deck.lan" "Pragmata")))
  (test code 127)
  (test (has? "Vault is locked" err) true)
  (test (rsyncs lines) @[])
  # RomM down, or the key revoked.
  (def [code _ err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_CURL_FAIL" "500"]
      (hey-steam "push" "deck.lan" "Pragmata")))
  (test code 127)
  (test (has? "RomM: https://romm.home.lissner.net/api/platforms failed" err) true)
  (test (rsyncs lines) @[])
  (def [code _ err _]
    (hey/with-envvars ["HEY_STEAM_TEST_CURL_FAIL" "401"]
      (hey-steam "push" "romm" "Pragmata")))
  (test code 127)
  (test (has? "rejected the API key" err) true))

(deftest push/first-run-enables-the-debugger
  # No marker on the remote yet: leave one, and stop until Steam has restarted.
  (def marker (string runtime "/.local/share/Steam/.cef-enable-remote-debugging"))
  (def [code _ err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_REPLY" "should never be asked"]
      (hey-steam* (fn [] (reset) (os/rm marker)) "push" "deck.lan" "Pragmata")))
  (test code 127)
  (test (has? "Restart Steam there" err) true)
  (test (os/stat marker :mode) :file)
  # Nothing was copied or asked of Steam first.
  (test (rsyncs lines) @[])
  (test (has? "python3" (string/join lines "\n")) false))

(deftest push/no-saves
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "Pragmata" "--no-saves"))
  (test code 0)
  (test (length (rsyncs lines)) 1)
  (test (has? "python3" (string/join lines "\n")) true))

(deftest push/existing-shortcut-follows-the-files
  (def [code out err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_REPLY" `{"appid": 4242, "created": false, "exe": "/somewhere/else/PRAGMATA.exe"}`]
      (hey-steam "push" "deck.lan" "Pragmata")))
  (test code 0)
  (test (has? "ran /somewhere/else/PRAGMATA.exe; it now runs" err) true)
  (test (has? "already on deck.lan as 4242" out) true)
  # Same appid, so the saves went to the prefix it already had.
  (test (get (last (requests)) :dir) ".local/share/Steam/steamapps/compatdata/4242/pfx/drive_c/users/steamuser")
  (def js (string (slurp (string log ".js"))))
  (test (has? "if (oldExe !== exe) {" js) true)
  (test (has? "SetShortcutExe(appid, exe)" js) true)
  (test (has? "SetShortcutStartDir(appid, startDir)" js) true))

(deftest push/refusals
  (test (first (hey-steam "push" "deck.lan" "Nope")) 127)
  (test (first (hey-steam "push" "deck.lan")) 127)
  (test (first (hey-steam "push")) 127)
  # ES-DE's exe isn't in its start dir; nothing touched the remote finding that out.
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "ES-DE"))
  (test code 127)
  (test (remote-calls lines) @[]))

(deftest push/dry-run
  (def [code out err lines] (hey-steam "push" "-!" "deck.lan" "Pragmata"))
  (test code 0)
  # RomM is read, the Deck is never touched, and the helper here only looks.
  (test (remote-calls lines) @[])
  (test (map |[($0 :direction) ($0 :dry_run)] (requests)) @[["upload" true]])
  (test (has? "upload saveFile" (curl-log)) false)
  (def all (string out err))
  (test (filter |(string/find "/content/" $0) lines) @[])
  (test (has? "romm: download Pragmata.zip and unpack it into" out) true)
  (test (has? (string "DRYRUN: rsync -rltDP " unpacked "/Pragmata/ deck.lan:$STEAM_LIBRARY/Games/Pragmata/") all) true)
  (test (has? "romm: upload Pragmata.zip from here (2 files)" out) true)
  (test (has? "romm: deck.lan downloads Pragmata.zip into .local/share/Steam/steamapps/compatdata/0/pfx" out) true)
  (test (has? `AddShortcut "Pragmata"` out) true))

(deftest rm
  (def game (string runtime "/Games/PRAGMATA"))
  (def prefix (string runtime "/.local/share/Steam/steamapps/compatdata/4242"))
  (def grid (string runtime "/.local/share/Steam/userdata/" uid "/config/grid"))
  (defn plant []
    (reset)
    ($ mkdir -p ,game ,grid) (spit (string game "/PRAGMATA.exe") "")
    (spit (string grid "/4242p.png") "") (spit (string grid "/4242_hero.jpg") "") (spit (string grid "/4243p.png") ""))
  (def [code out err lines] (hey-steam* plant "rm" "deck.lan" "Pragmata"))
  (test code 0)
  # $HOME-less steps: uname, the vdf, the marker, $HOME, the library list; then files, shortcut, art.
  (test (verbs lines) @["ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan"])
  (test (truthy? (index-of (string "ssh deck.lan rm -rf '" game "'") lines)) true)
  (test (os/stat game) nil)
  (test (string (slurp (string log ".js"))) "SteamClient.Apps.RemoveShortcut(4242)")
  (test (os/stat (string grid "/4242p.png")) nil)
  (test (os/stat (string grid "/4242_hero.jpg")) nil)
  (test (os/stat (string grid "/4243p.png") :mode) :file)
  # The prefix is the saves: kept, and said so.
  (test (os/stat prefix :mode) :directory)
  (test (has? "--saves deletes them" err) true)
  (test (has? "Pragmata ✗ deck.lan (4242)" out) true)
  # --saves
  (def [code _ err lines] (hey-steam* plant "rm" "deck.lan" "Pragmata" "--saves"))
  (test code 0)
  (test (os/stat prefix) nil)
  (test (has? "--saves deletes them" err) false)
  # Not somewhere push would have put it: the files stay.
  (def [code _ err lines] (hey-steam* plant "rm" "deck.lan" "Konsole"))
  (test code 0)
  (test (filter |(string/find " rm -rf " $0) lines) @[])
  (test (has? "leaving it alone" err) true)
  (test (string (slurp (string log ".js"))) "SteamClient.Apps.RemoveShortcut(999)")
  # $HOME/Games counts even when the library has moved.
  (def [code _ err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_LIBRARIES" (string (json/encode @[@{:path (string runtime "/sd") :default true :mounted true}]))]
      (hey-steam* plant "rm" "deck.lan" "Pragmata" "--saves")))
  (test code 0)
  (test (os/stat game) nil)
  # Dry-run: reads only.
  (def [code out _ lines] (hey-steam* plant "rm" "-!" "deck.lan" "Pragmata"))
  (test code 0)
  (test (os/stat game :mode) :directory)
  (test (has? "RemoveShortcut 4242" out) true)
  (test (filter |(string/find " rm " $0) lines) @[])
  (test (filter |(string/find "touch" $0) lines) @[])
  (test (first (hey-steam "rm" "deck.lan" "Nope")) 127)
  (test (first (hey-steam "rm" "deck.lan")) 127))

(deftest pull
  (def [code out _ lines] (hey-steam "pull" "deck.lan" "Pragmata"))
  (test code 0)
  # uname, the vdf; RomM's side; the helper there, the upload, the helper here.
  (test (verbs lines)
        @["ssh deck.lan" "ssh deck.lan"
          "rbw unlocked" "rbw get"
          "curl https://romm.home.lissner.net/api/platforms"
          "curl https://romm.home.lissner.net/api/roms?limit=50&platform_ids=3&search_term=Pragmata"
          "curl https://romm.home.lissner.net/api/saves?rom_id=7231"
          "curl https://romm.home.lissner.net/api/saves/99/content"
          "ssh deck.lan" "python3 -I"
          "curl https://romm.home.lissner.net/api/saves?autocleanup=true&autocleanup_limit=10&emulator=proton&rom_id=7231&slot=proton"
          "python3 -I"])
  (test (rsyncs lines) @[])
  (def [up down] (requests))
  # Up from the prefix Steam on the Deck handed out, down into mine.
  (test (up :direction) "upload")
  (test (up :dir) ".local/share/Steam/steamapps/compatdata/4242/pfx/drive_c/users/steamuser")
  (test (up :latest) @{:content_hash "h99" :updated_at "2026-11-09T13:02:11Z"})
  (test (down :direction) "download")
  (test (= (down :dir) (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser")) true)
  (test (down :latest) @{:content_hash "h100" :updated_at "2026-11-10T00:00:00Z"})
  (test (map |($0 :force) [up down]) @[false false])
  (test (has? "Pragmata: deck.lan → RomM (2 files, save 100)" out) true)
  (test (has? "Pragmata: RomM → here (2 files)" out) true)
  (test (has? "Pragmata ← deck.lan (4242)" out) true)
  (hey-steam "pull" "deck.lan" "Pragmata" "--force")
  (test (map |($0 :force) (requests)) @[true true]))

(deftest pull/romm-host
  # RomM as HOST: the download leg only.
  (def [code out _ lines] (hey-steam "pull" "romm" "Pragmata"))
  (test code 0)
  (test (remote-calls lines) @[])
  (test (map |[($0 :direction) ($0 :mkpath)] (requests)) @[["download" false]])
  (test (= (get (first (requests)) :dir) (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser")) true)
  (test (has? "upload saveFile" (curl-log)) false)
  (test (has? "Pragmata ← romm" out) true)
  # No prefix here to receive it: stop before RomM is asked.
  (def [code _ err lines] (hey-steam "pull" "romm" "Trails in the Sky: Chapter 1"))
  (test code 127)
  (test (has? "no prefix here" err) true)
  (test lines @[])
  (test (first (hey-steam "pull" "romm" "Pragmata" "--direct")) 127))

(deftest pull/direct
  (def [code out _ lines] (hey-steam "pull" "deck.lan" "Pragmata" "--direct"))
  (test code 0)
  # uname, the vdf, the saves.
  (test (verbs lines) @["ssh deck.lan" "ssh deck.lan" "rsync -rltDzP"])
  (def argv (words (last lines)))
  (test (get argv (- (length argv) 2)) "deck.lan:.local/share/Steam/steamapps/compatdata/4242/pfx/drive_c/users/steamuser/")
  (test (= (last argv) (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser/")) true)
  (test (truthy? (index-of "-u" argv)) true)
  (test (truthy? (index-of "--delete" argv)) false)
  (test (length (filter |(string/has-prefix? "--exclude=/AppData/Local/" $0) argv)) 9)
  (test (has? "Pragmata ← deck.lan (4242)" out) true)
  (test (truthy? (index-of "-u" (words (last (get (hey-steam "pull" "deck.lan" "Pragmata" "--direct" "--force") 3))))) false))

(deftest pull/refusals
  # Known here, not there.
  (def [code _ err lines] (hey-steam "pull" "deck.lan" "ES-DE"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (has? "on deck.lan" err) true)
  # Known there, no prefix here to receive it.
  (def [code _ err lines] (hey-steam "pull" "deck.lan" "Trails in the Sky: Chapter 1"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (has? "no prefix here" err) true)
  (test (filter |(string/has-prefix? "curl " $0) lines) @[])
  (test (first (hey-steam "pull" "deck.lan" "Nope")) 127)
  (test (first (hey-steam "pull")) 127))

## GameNative (Android) hosts

(deftest retroid/folder-name
  (test (retroid/folder-name "Trails in the Sky: Chapter 1") "Trails in the Sky - Chapter 1")
  (test (retroid/folder-name "Fuga: Melodies of Steel") "Fuga - Melodies of Steel")
  (test (retroid/folder-name `What? "Yes"/No:1|2*`) "What YesNo -12")
  (test (retroid/folder-name "Pragmata") "Pragmata"))

(deftest retroid/find-game
  (def games [{:name "Trails in the Sky - Chapter 1"} {:name "pragmata"}])
  (test (retroid/find-game games "Trails in the Sky: Chapter 1") {:name "Trails in the Sky - Chapter 1"})
  (test (retroid/find-game games "Trails in the Sky - Chapter 1") {:name "Trails in the Sky - Chapter 1"})
  (test (retroid/find-game games "Pragmata") {:name "pragmata"})
  (test (retroid/find-game games "Fuga") nil))

(deftest android/ls
  (def [code out _ lines] (hey-android "ls" "rp6.lan"))
  (test code 0)
  # uname, the SD card, the listing: no vdf, no python.
  (test (verbs lines) @["ssh rp6.lan" "ssh rp6.lan" "ssh rp6.lan"])
  (test (has? "python3" (string/join lines "\n")) false)
  (test (deep= (string/split "\n" (string/trim out))
               @[(string "Fuga - Melodies of Steel                -            " games-dir "/Fuga - Melodies of Steel/TANK.exe")
                 (string "Hollow Knight                           -  mbx       " games-dir "/Hollow Knight/hollow_knight.exe")
                 (string "Pragmata                                -  mbx       " games-dir "/Pragmata/Bin/PRAGMATA.exe")
                 (string "Trails in the Sky - Chapter 1           -  mbx       " games-dir "/Trails in the Sky - Chapter 1/sora_1st.exe")])
        true)
  (test (get (hey-android "ls" "-n" "rp6.lan") 1) "Fuga - Melodies of Steel\nHollow Knight\nPragmata\nTrails in the Sky - Chapter 1\n"))

(deftest android/push
  (def [code out err lines] (hey-android "push" "rp6.lan" "Fuga: Melodies of Steel" "--seed"))
  (test code 0)
  # uname, the SD card, mkdir; the game; mkdir for the mailbox; the saves (no
  # -l: shared storage has no symlinks). No Steam, and no python: the saves
  # are my prefix's, so the helper isn't needed.
  (test (verbs (remote-calls lines)) @["ssh rp6.lan" "ssh rp6.lan" "ssh rp6.lan" "rsync -rltDP" "ssh rp6.lan" "rsync -rtDzP"])
  (test (has? "python3" (string/join lines "\n")) false)
  (def [game saves] (rsyncs lines))
  # Under GameNative/CustomGames on the card, named after the shortcut, not RomM's file.
  (test (= game (string "rsync -rltDP " unpacked "/Fuga - Melodies of Steel/ rp6.lan:" games-dir "/Fuga - Melodies of Steel/")) true)
  (test (os/stat (string games-dir "/Fuga - Melodies of Steel") :mode) :directory)
  # Into the mailbox itself (no subdir), by its absolute path, never through
  # ~/storage/shared; and made over ssh, not --mkpath.
  (test (string/has-suffix? (string " " steam-dir "/steamapps/compatdata/2894349286/pfx/drive_c/users/steamuser/"
                                    " rp6.lan:/storage/emulated/0/Download/GameNative/Fuga - Melodies of Steel/")
                            saves)
        true)
  (test (truthy? (index-of "-u" (words saves))) true)
  (test (truthy? (index-of "--mkpath" (words saves))) false)
  (test (os/stat (string mailbox "/Fuga - Melodies of Steel") :mode) :directory)
  (test (truthy? (index-of "--delete" (words saves))) false)
  (test (length (filter |(string/has-prefix? "--exclude=/AppData/Local/" $0) (words saves))) 9)
  # GameNative finds GameNative/CustomGames on its own; the import step, and the ignored flag, are mentioned.
  (test (has? (string "it scans " games-dir " on its own") out) true)
  (test (has? "Import Files" err) true)
  (test (has? "--seed ignored" err) true)
  (test (has? "Fuga: Melodies of Steel → rp6.lan" out) true))

(deftest android/push/first-time
  # No GameNative/CustomGames on the card yet: mkdir makes it, GameNative will find it.
  (def [code out _ lines] (hey-android* (fn [] (reset-android) ($ rm -rf ,games-dir)) "push" "rp6.lan" "Pragmata" "--no-saves"))
  (test code 0)
  (test (length (rsyncs lines)) 1)
  (test (has? (string "it scans " games-dir " on its own") out) true)
  (test (os/stat (string games-dir "/Pragmata") :mode) :directory))

(deftest android/push/romm-save
  # No shortcut here, so no prefix: RomM's save is unpacked here (the helper
  # runs on this side, never on the Retroid) and rsynced into the mailbox.
  (def [code out err lines] (hey-android "push" "rp6.lan" "Hollow Knight"))
  (test code 0)
  (test (filter |(and (string/has-prefix? "ssh " $0) (string/find "python3" $0)) lines) @[])
  (test (map |[($0 :direction) ($0 :mkpath)] (requests)) @[["download" true]])
  (test (= (get (first (requests)) :dir) (string cache "/hey/romm/saves/Hollow Knight")) true)
  (def [game saves] (rsyncs lines))
  (test (= game (string "rsync -rltDP " unpacked "/Hollow Knight/ rp6.lan:" games-dir "/Hollow Knight/")) true)
  (test (string/has-suffix? (string " " cache "/hey/romm/saves/Hollow Knight/"
                                    " rp6.lan:/storage/emulated/0/Download/GameNative/Hollow Knight/")
                            saves)
        true)
  (test (has? "Import Files" err) true)
  # Nothing on RomM for it either: nothing to send, and said so.
  (def [code _ err lines] (hey-android "push" "rp6.lan" "Quake" "-e" "quake.exe"))
  (test code 0)
  (test (length (rsyncs lines)) 1)
  (test (requests) @[])
  (test (has? "no proton save on RomM yet, and no prefix here" err) true))

(deftest android/push/no-sd-card
  (def [code _ err lines] (hey-android* (fn [] (reset-android) ($ rm -rf ,sd)) "push" "rp6.lan" "Pragmata"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (has? "No SD card in rp6.lan" err) true))

(deftest android/push/dry-run
  (def [code out err lines] (hey-android "push" "-!" "-g" "rp6.lan" "Pragmata"))
  (test code 0)
  # RomM is read, nothing is fetched, the Retroid is never touched.
  (test (remote-calls lines) @[])
  (test (filter |(string/find "/content/" $0) lines) @[])
  (def all (string out err))
  (test (has? (string "DRYRUN: rsync -rltDP " unpacked "/Pragmata/ rp6.lan:$SDCARD/GameNative/CustomGames/Pragmata/") all) true)
  (test (has? "rp6.lan:/storage/emulated/0/Download/GameNative/Pragmata/" all) true)
  (test (has? "AddShortcut" all) false))

(deftest android/pull
  # The export comes here into the cache, goes up to RomM from there, and
  # RomM's newest comes down into my prefix; the device never runs python.
  (def [code out _ lines] (hey-android "pull" "rp6.lan" "Pragmata"))
  (test code 0)
  # uname, the SD card, the listing, the export.
  (test (verbs (remote-calls lines)) @["ssh rp6.lan" "ssh rp6.lan" "ssh rp6.lan" "rsync -rltDzP"])
  (def argv (words (first (rsyncs lines))))
  (test (get argv (- (length argv) 2)) "rp6.lan:/storage/emulated/0/Download/GameNative/Pragmata/")
  (test (= (last argv) (string cache "/hey/romm/saves/Pragmata/")) true)
  (test (truthy? (index-of "-u" argv)) false)
  (test (length (filter |(string/has-prefix? "--exclude=/AppData/Local/" $0) argv)) 9)
  (test (deep= (map |[($0 :direction) ($0 :dir)] (requests))
               @[["upload" (string cache "/hey/romm/saves/Pragmata")]
                 ["download" (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser")]])
        true)
  (test (has? "upload saveFile" (curl-log)) true)
  (test (has? "python3" (string/join (remote-calls lines) "\n")) false)
  (test (has? "Pragmata ← rp6.lan" out) true)
  (hey-android "pull" "rp6.lan" "Pragmata" "--force")
  (test (map |($0 :force) (requests)) @[true true]))

(deftest android/pull/no-prefix
  # No shortcut here, so no prefix: the save still goes up, under the
  # folder's name, and pull says where it is.
  (def [code out err lines] (hey-android "pull" "rp6.lan" "Hollow Knight"))
  (test code 0)
  (test (deep= (map |[($0 :direction) ($0 :dir)] (requests)) @[["upload" (string cache "/hey/romm/saves/Hollow Knight")]]) true)
  (test (has? "upload saveFile" (curl-log)) true)
  (test (has? "Hollow Knight has no prefix here; its save is on RomM" err) true)
  (test (has? "Hollow Knight ← rp6.lan" out) true)
  # A shortcut here that's never run is the same, and the folder's name does
  # as well as the shortcut's; but RomM hasn't got Trails, which ends it.
  (def [code _ err lines] (hey-android "pull" "rp6.lan" "Trails in the Sky - Chapter 1"))
  (test code 127)
  (test (has? "Add win/roms/Trails in the Sky: Chapter 1.*" err) true)
  (test (rsyncs lines) @[])
  # --direct wants the prefix, as before.
  (def [code _ err lines] (hey-android "pull" "rp6.lan" "Trails in the Sky: Chapter 1" "--direct"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (has? "launch it once" err) true))

(deftest android/pull/direct
  (def [code out _ lines] (hey-android "pull" "rp6.lan" "Pragmata" "--direct"))
  (test code 0)
  (test (verbs lines) @["ssh rp6.lan" "ssh rp6.lan" "ssh rp6.lan" "rsync -rltDzP"])
  (def argv (words (last lines)))
  (test (get argv (- (length argv) 2)) "rp6.lan:/storage/emulated/0/Download/GameNative/Pragmata/")
  (test (= (last argv) (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser/")) true)
  (test (truthy? (index-of "-u" argv)) true)
  (test (requests) @[])
  (test (truthy? (index-of "-u" (words (last (get (hey-android "pull" "rp6.lan" "Pragmata" "--direct" "--force") 3))))) false))

(deftest android/pull/refusals
  # There, but never exported: nothing to read, say what to click.
  (def [code _ err lines] (hey-android "pull" "rp6.lan" "Fuga: Melodies of Steel"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (has? "Export Files" err) true)
  # Known here, not there.
  (def [code _ err lines] (hey-android "pull" "rp6.lan" "ES-DE"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (has? "on rp6.lan" err) true)
  (test (first (hey-android "pull" "rp6.lan" "Nope")) 127)
  # Dry-run: reads only, nothing goes up.
  (def [code _ _ lines] (hey-android "pull" "-!" "rp6.lan" "Pragmata"))
  (test code 0)
  (test (rsyncs lines) @[])
  (test (has? "upload saveFile" (curl-log)) false))

(deftest android/rm
  (def [code out err lines] (hey-android "rm" "rp6.lan" "Pragmata"))
  (test code 0)
  (test (has? "python3" (string/join lines "\n")) false)
  (test (os/stat (string games-dir "/Pragmata")) nil)
  (test (os/stat (string games-dir "/Fuga - Melodies of Steel") :mode) :directory)
  # The export is the only saves we can reach: kept, and said so; the UI does the rest.
  (test (os/stat (string mailbox "/Pragmata") :mode) :directory)
  (test (has? "--saves deletes them" err) true)
  (test (has? "remove both in its UI" err) true)
  (test (has? "Pragmata ✗ rp6.lan" out) true)
  (def [code _ err _] (hey-android "rm" "rp6.lan" "Pragmata" "--saves"))
  (test code 0)
  (test (os/stat (string mailbox "/Pragmata")) nil)
  (test (has? "--saves deletes them" err) false)
  # Dry-run: reads only.
  (def [code _ _ lines] (hey-android "rm" "-!" "-g" "rp6.lan" "Pragmata"))
  (test code 0)
  (test (os/stat (string games-dir "/Pragmata") :mode) :directory)
  (test (filter |(string/find " rm " $0) lines) @[])
  (test (first (hey-android "rm" "rp6.lan" "Nope")) 127))
