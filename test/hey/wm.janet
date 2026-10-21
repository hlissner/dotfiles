#!/usr/bin/env janet
# Regression tests for bin/hey.d/wm.janet, bin/hey.d/wm.d/* and lib/hey/wm.janet.
#
# hey wm is two things in one table: commands compiled into hey, and a fallback
# into config/$WM/bin for everything else. Both halves are pinned here, since
# losing either one is silent -- a keybind that plays nothing, or a script that
# stops being found. The compiled commands speak to niri through
# lib/hey/wm.janet, so each one runs against a stubbed niri (wm.d/bin)
# answering from canned JSON (wm.d/fixtures).

(use judge)
(use sh)
(import hey)
(import hey/wm)

(def- bin (hey/path :home "bin/hey"))
(def- stubs (hey/path :test "hey/wm.d/bin"))
(def- fixtures (hey/path :test "hey/wm.d/fixtures"))
(def- desktops (hey/path :test "hey/lib.d"))
# assets/sounds rides in by symlink, beside a stand-in freedesktop theme, so
# inheritance doesn't hinge on what this machine has installed.
(def- sounds (hey/path :test "hey/lib.d/niri/sounds"))
(def- scripts
  (sorted (seq [file :in (os/dir (hey/path :home "bin/hey.d/wm.d"))
                :when (string/has-suffix? ".janet" file)]
            (hey/string/no-suffix ".janet" file))))

(def- scratch
  (let [dir (hey/path :runtime "test.d")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    (hey/path/join dir (string "wm-" (os/getpid)))))
(os/mkdir scratch)
(def- log (string scratch ".play"))
(def- wm-log (string scratch ".wm"))

(defn- hey-wm
  ``Run `hey wm ARGS` on DESKTOP's fixture info.json, with every compositor and
  desktop tool stubbed out, and return [exit-code output]. VARIANT picks an
  alternate fixture where one exists (workspaces-onscratchpad.json, say).``
  [desktop & args]
  (def [variant args] (if (keyword? (first args)) [(string (first args)) (slice args 1)] [nil args]))
  (def out @"")
  (def code
    (hey/with-envvars ["XDG_DATA_HOME" (hey/path/join desktops desktop)
                       # Ahead of $PATH in hey's exec-path; on $PATH alone the
                       # real binaries would win.
                       "XDG_BIN_HOME" stubs
                       # So the vars the commands keep land in scratch, and
                       # so does launch's ~/.config/niri/launch.kdl.
                       "XDG_RUNTIME_DIR" scratch
                       "XDG_CONFIG_HOME" (hey/path/join scratch "config")
                       "HEY_TEST_PLAY_LOG" log
                       "HEY_TEST_WM_FIXTURES" fixtures
                       "HEY_TEST_WM_LOG" wm-log
                       "HEY_TEST_WM_VARIANT" variant]
      (first (run ,bin wm ,;args > ,out > [stderr out]))))
  [code (string/trim out)])

(defn- played
  ``What play was asked, with the sounds dir abbreviated to @. A detached play
  can land after hey exits, so under WAIT? this gives it a moment to.``
  [wait?]
  (var text "")
  (repeat 20
    (set text (string/trim (slurp log)))
    (unless (and wait? (empty? text)) (break))
    (os/sleep 0.05))
  (string/replace-all sounds "@" text))

(defn- play-sound [& args]
  (spit log "")
  (def [code] (hey-wm "niri" "play-sound" ;args))
  [code (played (zero? code))])

(defn- says? [[_ out] text] (not= nil (string/find text out)))

(defn- asked
  ``What the stubs logged during the last hey-wm, as lines; only those starting
  with PREFIX, if given. A detached toast can land after hey exits, so the
  noctalia lines aren't to be counted on.``
  [&opt prefix]
  (def lines (filter |(not (empty? $0)) (string/split "\n" (string (slurp wm-log)))))
  (if prefix (filter |(string/has-prefix? prefix $0) lines) lines))

(defn- asked-eventually
  "asked, for a detached stub that may log after hey has exited."
  [prefix]
  (var lines @[])
  (repeat 20
    (set lines (asked prefix))
    (unless (empty? lines) (break))
    (os/sleep 0.05))
  lines)

(defn- fresh [] (spit wm-log ""))


(deftest wm/dispatch-table
  # bin/hey.d/wm.d/foo.janet with no import or rule in wm.janet would only
  # exist on disk -- and _hey would still offer it, since it scans wm.d.
  (def out @"")
  (hey/with-envvars ["XDG_DATA_HOME" (hey/path/join desktops "niri")]
    ($? ,bin help --dump wm > ,out))
  (test (deep= (sorted (seq [line :in (string/split "\n" (string out))
                             :until (empty? line)]
                         (first (string/split ":" line))))
               scripts)
        true))

(deftest wm/play-sound
  (test (play-sound "-w" "-v" "0.5" "blip") [0 "-q -v 0.5 @/hey/stereo/blip.ogg"])
  # Detached by default: hey is long gone by the time play logs anything.
  # Mine, though freedesktop has one too.
  (test (play-sound "success") [0 "-q @/hey/stereo/success.ogg"])
  # Sheds -parts before falling back to a parent, like Noctalia.
  (test (play-sound "success-at-last") [0 "-q @/hey/stereo/success.ogg"])
  (test (play-sound "bell") [0 "-q @/freedesktop/stereo/bell.oga"])
  # Found, but silenced: nothing plays, and that's not an error.
  (test (play-sound "-w" "hush") [0 ""])
  (test (play-sound "no-such-sound") [127 ""])
  (test (says? (hey-wm "niri" "play-sound") "Usage:") true)
  # Names, as they'd be passed back in, rather than files.
  (def [code out] (hey-wm "niri" "play-sound" "ls"))
  (test code 0)
  (def names (string/split "\n" out))
  (test (truthy? (index-of "blip" names)) true)
  (test (truthy? (index-of "bell" names)) true)
  (test (index-of "hush" names) nil))

(deftest wm/fallback
  # Anything the table doesn't name is a script in config/$WM/bin, and a name
  # that isn't there either is a sentence naming the directory (which niri
  # hasn't got at all).
  (def r (hey-wm "niri" "no-such-script"))
  (test (first r) 127)
  (test (says? r "config/niri/bin: not found") true)
  # No desktop is a sentence, not a backtrace -- and doesn't take the compiled
  # commands down with it, since they never needed one.
  (test (first (hey-wm "unset" "no-such-script")) 127)
  (test (first (hey-wm "unset" "play-sound" "-w" "blip")) 0))

(deftest wm/pure-helpers
  (def snap (get-in (require "../../bin/hey.d/wm.d/volume") ['snap :value]))
  # To the next multiple of ten in the direction asked, never by ten.
  (test (snap 43 "up") 50)
  (test (snap 43 "down") 40)
  (test (snap 50 "down") 40)
  (test (snap 50 "up") 60)
  (test (snap 97 "up") 100)
  (test (snap 3 "down") 0)
  (test (snap 43 "up" 25) 50)
  (test (wm/parse-geometry "10,20 300x400") @[10 20 300 400])
  # A region can start left of the leftmost output.
  (test (wm/parse-geometry "-10,20 300x400") @[-10 20 300 400])
  (test (wm/parse-geometry "null,null nullxnull") nil)
  (test (wm/parse-geometry "") nil))

(deftest wm/outputs
  # In logical pixels, off ones included (with nothing where niri has no
  # logical size for them).
  (test (hey-wm "niri" "outputs" "-r" "name" "enabled" "width" "height")
        [0 "DP-1 true 2560 1440\nHDMI-A-1 false"])
  (test (hey-wm "niri" "outputs" "--focused" "-r" "name" "scale") [0 "DP-1 2"])
  (test (says? (hey-wm "niri" "outputs" "--focused") `"name": "DP-1"`) true))

(deftest wm/workspace-query
  (test (says? (hey-wm "niri" "workspace") `"id": 1`) true)
  (test (says? (hey-wm "niri" :onscratchpad "workspace") `"name": "scratchpad"`) true))

(deftest wm/slurp-window
  # Windows on a shown workspace, as boxes for slurp -r, reassembled from
  # output origin + tile + offset. Scrolled off (no tile position) and
  # hidden-workspace windows don't count.
  (fresh)
  (test (hey-wm "niri" "slurp" "window") [0 "10,20 300x400"])
  (test (asked "box") @["box 11,21 300x400"])
  # Cached, so `last` reads it back without a prompt.
  (fresh)
  (test (hey-wm "niri" "slurp" "last") [0 "10,20 300x400"])
  (test (asked "slurp") @[]))

(deftest wm/workspace-move
  (def origin (hey/path/join scratch "hey/vars.d/wm.origin.7"))
  (hey/ignore-errors (os/rm origin))
  # Into the named workspace from HDMI-A-1's (id 3, idx 1), remembering where
  # from. A name finds the workspace on any monitor.
  (fresh)
  (test (first (hey-wm "niri" :onhdmi "workspace" "move" "scratchpad")) 0)
  (test (asked "niri") @["niri msg action move-window-to-workspace --window-id 7 --focus true scratchpad"])
  (test (hey/path/file? origin) true)
  # And back out. niri reads a bare number as an index on the active monitor,
  # so that's a hop to HDMI-A-1 first and then its idx 1, never id 3.
  (fresh)
  (test (first (hey-wm "niri" :onscratchpad "workspace" "move" "scratchpad")) 0)
  (test (asked "niri") @["niri msg action move-window-to-monitor --id 7 HDMI-A-1"
                        "niri msg action move-window-to-workspace --window-id 7 --focus true 1"])
  (test (hey/path/file? origin) false)
  # Nothing remembered (a window that opened there): nowhere to go.
  (fresh)
  (test (first (hey-wm "niri" :onscratchpad "workspace" "move" "scratchpad")) 127)
  (test (asked "niri") @[])
  (test (first (hey-wm "niri" "workspace" "move" "nope")) 127)
  (test (first (hey-wm "niri" "workspace" "move")) 127))

(deftest wm/dropdown
  # No window yet: foot, named for the rule and the tmux session, and hey
  # doesn't wait for it.
  (fresh)
  (test (first (hey-wm "niri" "dropdown")) 0)
  (test (asked-eventually "foot") @["foot -T dropdown -a dropdown -o main.font=JetBrainsMono Nerd Font:size=9 -- tmux new -A -s dropdown"])
  (test (asked "niri") @[])
  # Parked on the scratchpad (id 2): dragged to the focused workspace, which
  # is unnamed, so by index on the focused output, and focused once there.
  (fresh)
  (test (first (hey-wm "niri" :dropdown "dropdown")) 0)
  (test (asked "niri") @["niri msg action move-window-to-workspace --window-id 10 1"
                        "niri msg action focus-window --id 10"])
  (test (asked "foot") @[])
  # Already here: dismissed, whether or not it has the focus.
  (fresh)
  (test (first (hey-wm "niri" :dropdownshown "dropdown")) 0)
  (test (asked "niri") @["niri msg action close-window --id 10"]))

(deftest wm/set-monitors
  # Enable what's named, disable the rest; placeholders aren't the rest.
  (fresh)
  (test (first (hey-wm "niri" "set-monitors" "DP-1")) 0)
  (test (asked "niri") @["niri msg output DP-1 on" "niri msg output HDMI-A-1 off"])
  # And says so, on the OSD. Fields, not the whole payload: a table's key
  # order is json/encode's business.
  (def osd (string ;(asked-eventually "noctalia msg osd-show")))
  (test (says? [0 osd] `"icon":"device-desktop"`) true)
  (test (says? [0 osd] `"value":"Set monitors: DP-1"`) true)
  (fresh)
  (test (first (hey-wm "niri" "set-monitors" "--off" "HDMI-A-1")) 0)
  (test (asked "niri") @["niri msg output HDMI-A-1 off"])
  (fresh)
  (test (first (hey-wm "niri" "set-monitors" "--on" "HDMI-A-1")) 0)
  (test (asked "niri") @["niri msg output HDMI-A-1 on"])
  (test (first (hey-wm "niri" "set-monitors")) 127))

(deftest wm/actions
  (fresh)
  (test (first (hey-wm "niri" "dpms" "off")) 0)
  (test (first (hey-wm "niri" "overview")) 0)
  (test (asked "niri") @["niri msg action power-off-monitors"
                        "niri msg action toggle-overview"])
  (test (first (hey-wm "niri" "overview" "all")) 127)
  (test (first (hey-wm "niri" "dpms" "sideways")) 127))

(deftest wm/rate
  # Only Supersonic gets rated. With foot focused the key is a no-op rather
  # than a stray `supersonic` call.
  (fresh)
  (test (first (hey-wm "niri" :onsupersonic "rate" "3")) 0)
  (test (first (hey-wm "niri" "rate" "3")) 0)
  (test (asked "supersonic") @["supersonic -rate-current 3"])
  (test (first (hey-wm "niri" "rate" "6")) 127))

(deftest wm/media
  (def origin (hey/path/join scratch "hey/vars.d/wm.media.origin"))
  (hey/ignore-errors (os/rm origin))
  # Over to the player (supersonic, by playerctl's name against the app-id),
  # remembering the window that had the focus.
  (fresh)
  (test (first (hey-wm "niri" "media")) 0)
  (test (asked "niri") @["niri msg action focus-window --id 9"])
  (test (hey/path/file? origin) true)
  # And back to that window, not merely its workspace.
  (fresh)
  (test (first (hey-wm "niri" :onsupersonic "media")) 0)
  (test (asked "niri") @["niri msg action focus-window --id 7"])
  (test (hey/path/file? origin) false)
  # Nothing remembered (focused by hand): the previous workspace is the best
  # guess.
  (fresh)
  (test (first (hey-wm "niri" :onsupersonic "media")) 0)
  (test (asked "niri") @["niri msg action focus-workspace-previous"]))

(deftest wm/volume
  (fresh)
  (test (first (hey-wm "niri" "volume" "sink" "up")) 0)
  (test (first (hey-wm "niri" "volume" "sink" "down")) 0)
  (test (first (hey-wm "niri" "volume" "player" "down")) 0)
  (test (first (hey-wm "niri" "volume" "-s" "25" "sink" "up")) 0)
  (test (asked "noctalia msg volume") @["noctalia msg volume-set 50"
                                        "noctalia msg volume-set 40"
                                        "noctalia msg volume-set 50"])
  (test (asked "playerctl volume ") @["playerctl volume 0.4"])
  (test (first (hey-wm "niri" "volume" "sink" "sideways")) 127))

(deftest wm/launch
  # The rule has to be live before the program maps a window, and gone once
  # the program is: COMMAND snapshots the include mid-flight, the suite reads
  # what's left after.
  (os/mkdir (hey/path/join scratch "config"))
  (def rules (hey/path/join scratch "config/niri/launch.kdl"))
  (def snap (hey/path/join scratch "launch.snap"))
  (defn launch [& args]
    (hey/ignore-errors (os/rm snap))
    (def [variant flags] (if (keyword? (first args)) [[(first args)] (slice args 1)] [[] args]))
    (hey-wm "niri" ;variant "launch" ;flags "-a" "^foo$" "-n" "foo" "--" "sh" "-c" (string "cp " rules " " snap)))
  (defn leftovers []
    (filter |(string/has-prefix? "wm.launch." $0) (os/dir (hey/path/join scratch "hey/vars.d"))))
  # --here on an unnamed focused workspace: named for the duration.
  (fresh)
  (test (first (launch)) 0)
  (test (asked "niri") @["niri msg action set-workspace-name --workspace 1 foo"
                        "niri msg action load-config-file"
                        "niri msg action load-config-file"
                        "niri msg action unset-workspace-name foo"])
  (test (string (slurp snap)) "window-rule {\n    match app-id=r#\"^foo$\"#\n    open-on-workspace \"foo\"\n}\n")
  (test (hey/path/file? rules) false)
  (test (leftovers) @[])
  # Already named (scratchpad): used as-is, left alone.
  (fresh)
  (test (first (launch :onscratchpad)) 0)
  (test (asked "niri") @["niri msg action load-config-file"
                        "niri msg action load-config-file"])
  (test (not= nil (string/find `open-on-workspace "scratchpad"` (string (slurp snap)))) true)
  # --empty: the bottom unnamed empty one on the focused output, not HDMI's.
  (fresh)
  (test (first (launch "--empty")) 0)
  (test (first (asked "niri")) "niri msg action set-workspace-name --workspace 3 foo")
  # The program's exit code is mine, and cleanup still happens.
  (fresh)
  (test (first (hey-wm "niri" "launch" "-a" "^foo$" "--" "sh" "-c" "exit 3")) 3)
  (test (last (asked "niri")) "niri msg action unset-workspace-name sh")
  (test (leftovers) @[])
  # NAME already taken elsewhere (scratchpad, on DP-1): a launch in flight
  # owns it, so this one targets it and leaves the name alone.
  (fresh)
  (test (first (hey-wm "niri" "launch" "-a" "^foo$" "-n" "scratchpad" "--" "sh" "-c" (string "cp " rules " " snap))) 0)
  (test (asked "niri") @["niri msg action load-config-file"
                        "niri msg action load-config-file"])
  (test (not= nil (string/find `open-on-workspace "scratchpad"` (string (slurp snap)))) true)
  # A command that can't even be spawned still gets the rule torn down.
  (fresh)
  (test (not= 0 (first (hey-wm "niri" "launch" "-a" "^foo$" "-n" "foo" "--" "/nonexistent/cmd"))) true)
  (test (last (asked "niri")) "niri msg action unset-workspace-name foo")
  (test (hey/path/file? rules) false)
  (test (leftovers) @[])
  (test (first (hey-wm "niri" "launch" "--" "true")) 127)
  (test (first (hey-wm "niri" "launch" "-a" "^foo$")) 127))
