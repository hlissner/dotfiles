#!/usr/bin/env janet
# Regression tests for lib/hey/steam.janet and bin/steam.d/*.
#
# ssh and rsync are stubs (steam.d/bin/*): rsync says what it was asked, ssh
# runs the remote command in a fake $HOME and answers the CEF client with
# whatever the suite says. What's pinned is the binary VDF reader, how a game
# moves house, and that push/pull send the right dir to the right prefix --
# the remote appid, never mine -- without ever deleting a save.

(use judge)
(use sh)
(import hey)
(import hey/steam)
(import spork/json)

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
                       "HEY_STEAM_TEST_REMOTE" runtime
                       "HEY_STEAM_TEST_LOG" log]
      (first (run ,bin .steam ,;args > ,out > [stderr err]))))
  [code (string out) (string err)
   (filter |(not (empty? $0)) (string/split "\n" (string (slurp log))))])

(defn- hey-steam
  "Run `hey .steam ARGS` against a fresh fake remote."
  [& args]
  (hey-steam* reset ;args))

(defn- words [line] (string/split " " line))
(defn- rsyncs [lines] (filter |(string/has-prefix? "rsync " $0) lines))
(defn- verbs [lines] (map |(string/join (take 2 (words $0)) " ") lines))

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
  (test (truthy? (string/find `const name = "Fuga: Melodies of Steel";` js)) true)
  (test (truthy? (string/find `const exe = "/home/deck/Games/F/TANK.exe";` js)) true)
  (test (truthy? (string/find `const launchOptions = "";` js)) true)
  (test (truthy? (string/find `const compat = "proton_experimental";` js)) true)
  (test (truthy? (string/find `const art = {"0":{"data":"UE5H","ext":"png"}};` js)) true)
  # By name, so a second push updates rather than duplicates.
  (test (truthy? (string/find "a.app_type === 1073741824 && a.display_name === name" js)) true)
  # ...and reports the old exe unquoted, so push can compare it to the one it'd set.
  (test (truthy? (string/find `d.strShortcutExe.replace(/^"(.*)"$/, '$1')` js)) true)
  (test (truthy? (string/find "SpecifyCompatTool(appid, compat)" js)) true)
  (def bare (steam/register-js {:name "x" :exe "/x" :start-dir "/" :launch-options "a %command%" :compat ""}))
  (test (truthy? (string/find `const launchOptions = "a %command%";` bare)) true)
  (test (truthy? (string/find `const compat = "";` bare)) true)
  (test (truthy? (string/find `const art = {};` bare)) true))

(deftest cdp-py
  # It only ever runs on the other machine, so at least make sure it parses...
  (test ($? python3 -I -c "import ast, sys; ast.parse(sys.stdin.read())" < ,(buffer steam/cdp-py)) true)
  # ...and survives the trip through the remote shell as one argument.
  (def out @"")
  ($ sh -c ,(string "printf %s " (hey/shell-quote steam/cdp-py)) > ,out)
  (test (= (string out) steam/cdp-py) true))

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

(deftest ls/remote
  (def [code out _ lines] (hey-steam "ls" "deck.lan"))
  (test code 0)
  (test (map |(take 2 (words $0)) (string/split "\n" (string/trim out)))
        @[["Pragmata" ""] ["Fuga:" "Melodies"] ["Trails" "in"] ["Konsole" ""]])
  (test (truthy? (string/find "4242  pfx" out)) true)
  (test (truthy? (string/find "777       " out)) true)
  (test (get (hey-steam "ls" "-n" "deck.lan") 1) "Pragmata\nFuga: Melodies of Steel\nTrails in the Sky: Chapter 1\nKonsole\n"))

(deftest push
  (def [code out err lines] (hey-steam "push" "deck.lan" "Pragmata"))
  (test code 0)
  # $HOME, the debugger marker, the library list; mkdir + the game; register; the prefix check + saves.
  (test (verbs lines)
        @["ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "rsync -rltDP" "ssh deck.lan" "ssh deck.lan" "rsync -rltDzP"])
  (def [game saves] (rsyncs lines))
  (test (= game (string "rsync -rltDP /media/data/games/PRAGMATA/ deck.lan:" runtime "/Games/PRAGMATA/")) true)
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
  # The game dir landed before anything was registered.
  (test (truthy? (index-of (string "ssh deck.lan mkdir -p '" runtime "/Games/PRAGMATA'") lines)) true)
  (test (os/stat (string runtime "/Games/PRAGMATA") :mode) :directory)
  # What Steam was told.
  (def js (string (slurp (string log ".js"))))
  (test (truthy? (string/find `const name = "Pragmata";` js)) true)
  (test (truthy? (string/find (string `const exe = "` runtime `/Games/PRAGMATA/PRAGMATA.exe";`) js)) true)
  (test (truthy? (string/find (string `const startDir = "` runtime `/Games/PRAGMATA";`) js)) true)
  (test (truthy? (string/find `const launchOptions = "";` js)) true)
  (test (truthy? (string/find `const compat = "proton_experimental";` js)) true)
  (test (truthy? (string/find `"ext":"png"` js)) true)
  (test (truthy? (string/find "Pragmata: added on deck.lan as 4242" out)) true)
  (test (truthy? (string/find "Pragmata → deck.lan (4242)" out)) true))

(deftest push/flags
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "pragmata" "-c" "GE-Proton" "-l" "x %command%" "--no-art" "--force"))
  (test code 0)
  (test (= (first (rsyncs lines)) (string "rsync -rltDP /media/data/games/PRAGMATA/ deck.lan:" runtime "/Games/PRAGMATA/")) true)
  (test (truthy? (index-of "-u" (words (last (rsyncs lines))))) false)
  (def js (string (slurp (string log ".js"))))
  (test (truthy? (string/find `const launchOptions = "x %command%";` js)) true)
  (test (truthy? (string/find `const compat = "GE-Proton";` js)) true)
  (test (truthy? (string/find `const art = {};` js)) true)
  (test (truthy? (string/find (string `const startDir = "` runtime `/Games/PRAGMATA";`) js)) true))

(deftest push/default-library
  # The Deck's default library is its SD card: games go in a Games/ there...
  (def libs (fn [& more] (string (json/encode @[@{:path (string runtime "/.local/share/Steam") :default false :mounted true} ;more]))))
  (def [code _ _ lines]
    (hey/with-envvars ["HEY_STEAM_TEST_LIBRARIES" (libs @{:path (string runtime "/sd") :default true :mounted true})]
      (hey-steam "push" "deck.lan" "Pragmata" "--no-saves")))
  (test code 0)
  (test (= (first (rsyncs lines)) (string "rsync -rltDP /media/data/games/PRAGMATA/ deck.lan:" runtime "/sd/Games/PRAGMATA/")) true)
  (test (truthy? (string/find (string `const exe = "` runtime `/sd/Games/PRAGMATA/PRAGMATA.exe";`) (string (slurp (string log ".js"))))) true)
  # ...unless it's unplugged.
  (def [_ _ _ lines]
    (hey/with-envvars ["HEY_STEAM_TEST_LIBRARIES" (libs @{:path (string runtime "/sd") :default true :mounted false})]
      (hey-steam "push" "deck.lan" "Pragmata" "--no-saves")))
  (test (= (first (rsyncs lines)) (string "rsync -rltDP /media/data/games/PRAGMATA/ deck.lan:" runtime "/Games/PRAGMATA/")) true))

(deftest push/no-prefix-yet
  # Fuga has never run on the Deck: say so, and don't invent a prefix...
  (def [code _ err lines] (hey-steam "push" "deck.lan" "Fuga: Melodies of Steel"))
  (test code 0)
  (test (length (rsyncs lines)) 1)
  (test (truthy? (string/find "Launch it there once" err)) true)
  # ...unless told to.
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "Fuga: Melodies of Steel" "--seed"))
  (test code 0)
  (test (length (rsyncs lines)) 2)
  (test (truthy? (index-of "--mkpath" (words (last (rsyncs lines))))) true)
  (test (string/has-suffix? " deck.lan:.local/share/Steam/steamapps/compatdata/777/pfx/drive_c/users/steamuser/" (last (rsyncs lines))) true))

(deftest push/first-run-enables-the-debugger
  # No marker on the remote yet: leave one, and stop until Steam has restarted.
  (def [code _ err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_REPLY" "should never be asked"]
      (do (reset)
          (os/rm (string runtime "/.local/share/Steam/.cef-enable-remote-debugging"))
          (def out @"") (def err @"")
          (def code (hey/with-envvars ["HOME" home "XDG_BIN_HOME" stubs
                                       "HEY_STEAM_TEST_REMOTE" runtime "HEY_STEAM_TEST_LOG" log]
                      (first (run ,bin .steam push deck.lan Pragmata > ,out > [stderr err]))))
          [code (string out) (string err) (string/split "\n" (string/trim (slurp log)))])))
  (test code 127)
  (test (truthy? (string/find "Restart Steam there" err)) true)
  (test (os/stat (string runtime "/.local/share/Steam/.cef-enable-remote-debugging") :mode) :file)
  # Nothing was copied or asked of Steam first.
  (test (rsyncs lines) @[])
  (test (truthy? (string/find "python3" (string/join lines "\n"))) false))

(deftest push/no-saves
  (def [code _ _ lines] (hey-steam "push" "deck.lan" "Pragmata" "--no-saves"))
  (test code 0)
  (test (length (rsyncs lines)) 1)
  (test (truthy? (string/find "python3" (string/join lines "\n"))) true))

(deftest push/existing-shortcut-follows-the-files
  (def [code out err lines]
    (hey/with-envvars ["HEY_STEAM_TEST_REPLY" `{"appid": 4242, "created": false, "exe": "/somewhere/else/PRAGMATA.exe"}`]
      (hey-steam "push" "deck.lan" "Pragmata")))
  (test code 0)
  (test (truthy? (string/find "ran /somewhere/else/PRAGMATA.exe; it now runs" err)) true)
  (test (truthy? (string/find "already on deck.lan as 4242" out)) true)
  # Same appid, so the saves went to the prefix it already had.
  (test (string/has-suffix? "compatdata/4242/pfx/drive_c/users/steamuser/" (last (rsyncs lines))) true)
  (def js (string (slurp (string log ".js"))))
  (test (truthy? (string/find "if (oldExe !== exe) {" js)) true)
  (test (truthy? (string/find "SetShortcutExe(appid, exe)" js)) true)
  (test (truthy? (string/find "SetShortcutStartDir(appid, startDir)" js)) true))

(deftest push/refusals
  (test (first (hey-steam "push" "deck.lan" "Nope")) 127)
  (test (first (hey-steam "push" "deck.lan" "ES-DE")) 127)
  (test (first (hey-steam "push" "deck.lan")) 127)
  (test (first (hey-steam "push")) 127)
  # Nothing touched the remote on the way to any of those.
  (test (get (hey-steam "push" "deck.lan" "ES-DE") 3) @[]))

(deftest push/dry-run
  (def [code out err lines] (hey-steam "push" "-!" "deck.lan" "Pragmata"))
  (test code 0)
  (test lines @[])
  (def all (string out err))
  (test (truthy? (string/find "DRYRUN: rsync -rltDP /media/data/games/PRAGMATA/ deck.lan:$STEAM_LIBRARY/Games/PRAGMATA/" all)) true)
  (test (truthy? (string/find "compatdata/0/pfx" all)) true)
  (test (truthy? (string/find `AddShortcut "Pragmata"` out)) true))

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
  # $HOME-less steps: the vdf, the marker, $HOME, the library list; then files, shortcut, art.
  (test (verbs lines) @["ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan" "ssh deck.lan"])
  (test (truthy? (index-of (string "ssh deck.lan rm -rf '" game "'") lines)) true)
  (test (os/stat game) nil)
  (test (string (slurp (string log ".js"))) "SteamClient.Apps.RemoveShortcut(4242)")
  (test (os/stat (string grid "/4242p.png")) nil)
  (test (os/stat (string grid "/4242_hero.jpg")) nil)
  (test (os/stat (string grid "/4243p.png") :mode) :file)
  # The prefix is the saves: kept, and said so.
  (test (os/stat prefix :mode) :directory)
  (test (truthy? (string/find "--saves deletes them" err)) true)
  (test (truthy? (string/find "Pragmata ✗ deck.lan (4242)" out)) true)
  # --saves
  (def [code _ err lines] (hey-steam* plant "rm" "deck.lan" "Pragmata" "--saves"))
  (test code 0)
  (test (os/stat prefix) nil)
  (test (truthy? (string/find "--saves deletes them" err)) false)
  # Not somewhere push would have put it: the files stay.
  (def [code _ err lines] (hey-steam* plant "rm" "deck.lan" "Konsole"))
  (test code 0)
  (test (filter |(string/find " rm -rf " $0) lines) @[])
  (test (truthy? (string/find "leaving it alone" err)) true)
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
  (test (truthy? (string/find "RemoveShortcut 4242" out)) true)
  (test (filter |(string/find " rm " $0) lines) @[])
  (test (filter |(string/find "touch" $0) lines) @[])
  (test (first (hey-steam "rm" "deck.lan" "Nope")) 127)
  (test (first (hey-steam "rm" "deck.lan")) 127))

(deftest pull
  (def [code out _ lines] (hey-steam "pull" "deck.lan" "Pragmata"))
  (test code 0)
  (test (verbs lines) @["ssh deck.lan" "rsync -rltDzP"])
  (def argv (words (last lines)))
  (test (get argv (- (length argv) 2)) "deck.lan:.local/share/Steam/steamapps/compatdata/4242/pfx/drive_c/users/steamuser/")
  (test (= (last argv) (string steam-dir "/steamapps/compatdata/3652376892/pfx/drive_c/users/steamuser/")) true)
  (test (truthy? (index-of "-u" argv)) true)
  (test (truthy? (index-of "--delete" argv)) false)
  (test (length (filter |(string/has-prefix? "--exclude=/AppData/Local/" $0) argv)) 9)
  (test (truthy? (string/find "Pragmata ← deck.lan (4242)" out)) true)
  (test (truthy? (index-of "-u" (words (last (get (hey-steam "pull" "deck.lan" "Pragmata" "--force") 3))))) false))

(deftest pull/refusals
  # Known here, not there.
  (def [code _ err lines] (hey-steam "pull" "deck.lan" "ES-DE"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (truthy? (string/find "on deck.lan" err)) true)
  # Known there, no prefix here to receive it.
  (def [code _ err lines] (hey-steam "pull" "deck.lan" "Trails in the Sky: Chapter 1"))
  (test code 127)
  (test (rsyncs lines) @[])
  (test (truthy? (string/find "no prefix here" err)) true)
  (test (first (hey-steam "pull" "deck.lan" "Nope")) 127)
  (test (first (hey-steam "pull")) 127))
