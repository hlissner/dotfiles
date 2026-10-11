#!/usr/bin/env janet
# Regression tests for bin/hey.d/wm.janet, bin/hey.d/wm.d/* and lib/hey/wm.janet.
#
# hey wm is two things in one table: commands compiled into hey, and a fallback
# into config/$WM/bin for everything else. Both halves are pinned here, since
# losing either one is silent -- a keybind that plays nothing, or a script that
# stops being found. The compiled commands speak to hyprland and niri through
# lib/hey/wm.janet, so each one runs under both desktops against stubbed
# hyprctl/niri binaries (wm.d/bin) answering from canned JSON (wm.d/fixtures).

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
(def- sounds (hey/path :test "hey/lib.d/hyprland/sounds"))
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
  alternate fixture where one exists (workspaces-onmedia.json, say).``
  [desktop & args]
  (def [variant args] (if (keyword? (first args)) [(string (first args)) (slice args 1)] [nil args]))
  (def out @"")
  (def code
    (hey/with-envvars ["XDG_DATA_HOME" (hey/path/join desktops desktop)
                       # Ahead of $PATH in hey's exec-path; on $PATH alone the
                       # real binaries would win.
                       "XDG_BIN_HOME" stubs
                       # So the vars the commands keep land in scratch.
                       "XDG_RUNTIME_DIR" scratch
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
  (def [code] (hey-wm "hyprland" "play-sound" ;args))
  [code (played (zero? code))])

(defn- says? [[_ out] text] (not= nil (string/find text out)))

(defn- asked
  ``What the stubs logged during the last hey-wm, as lines; only those starting
  with PREFIX, if given. A detached toast can land after hey exits, so the
  noctalia lines aren't to be counted on.``
  [&opt prefix]
  (def lines (filter |(not (empty? $0)) (string/split "\n" (string (slurp wm-log)))))
  (if prefix (filter |(string/has-prefix? prefix $0) lines) lines))

(defn- fresh [] (spit wm-log ""))


(deftest wm/dispatch-table
  # bin/hey.d/wm.d/foo.janet with no import or rule in wm.janet would only
  # exist on disk -- and _hey would still offer it, since it scans wm.d.
  (def out @"")
  (hey/with-envvars ["XDG_DATA_HOME" (hey/path/join desktops "hyprland")]
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
  (test (says? (hey-wm "hyprland" "play-sound") "Usage:") true)
  # Names, as they'd be passed back in, rather than files.
  (def [code out] (hey-wm "hyprland" "play-sound" "ls"))
  (test code 0)
  (def names (string/split "\n" out))
  (test (truthy? (index-of "blip" names)) true)
  (test (truthy? (index-of "bell" names)) true)
  (test (index-of "hush" names) nil))

(deftest wm/fallback
  # Anything the table doesn't name is a script in config/$WM/bin, and a name
  # that isn't there either is a sentence naming the directory (which hyprland
  # no longer has at all).
  (def r (hey-wm "hyprland" "no-such-script"))
  (test (first r) 127)
  (test (says? r "config/hypr/bin: not found") true)
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
  # The same columns under either desktop, in logical pixels, off ones
  # included (with nothing where niri has no logical size for them).
  (test (hey-wm "hyprland" "outputs" "-r" "name" "enabled" "width" "height")
        [0 "DP-1 true 2560 1440\nHDMI-A-1 false 0 0\nUnknown-1 true 1024 768"])
  (test (hey-wm "niri" "outputs" "-r" "name" "enabled" "width" "height")
        [0 "DP-1 true 2560 1440\nHDMI-A-1 false"])
  (test (hey-wm "hyprland" "outputs" "--focused" "-r" "name" "scale") [0 "DP-1 2"])
  (test (hey-wm "niri" "outputs" "--focused" "-r" "name" "scale") [0 "DP-1 2"])
  (test (says? (hey-wm "niri" "outputs" "--focused") `"name": "DP-1"`) true))

(deftest wm/workspace-query
  # hyprland: the special workspace DP-1 is showing is what's focused, not the
  # workspace underneath it that hyprctl activeworkspace would report.
  (test (says? (hey-wm "hyprland" "workspace") `"name": "special:media"`) true)
  (test (says? (hey-wm "niri" "workspace") `"id": 1`) true)
  (test (says? (hey-wm "niri" :onmedia "workspace") `"name": "media"`) true))

(deftest wm/slurp-window
  # Windows on a shown workspace, as boxes for slurp -r: hyprland's own
  # coordinates, niri's reassembled from output origin + tile + offset. Scrolled
  # off (no tile position), unmapped, and hidden-workspace windows don't count.
  (fresh)
  (test (hey-wm "hyprland" "slurp" "window") [0 "10,20 300x400"])
  (test (asked "box") @["box 10,20 300x400" "box 100,100 50x50"])
  (fresh)
  (test (hey-wm "niri" "slurp" "window") [0 "10,20 300x400"])
  (test (asked "box") @["box 11,21 300x400"])
  # Cached, so `last` reads it back without a prompt.
  (fresh)
  (test (hey-wm "niri" "slurp" "last") [0 "10,20 300x400"])
  (test (asked "slurp") @[]))

(deftest wm/workspace-toggle
  (fresh)
  (test (first (hey-wm "niri" "workspace" "toggle" "media")) 0)
  (test (asked "niri") @["niri msg action focus-workspace media"])
  # Already there: back to wherever I was.
  (fresh)
  (test (first (hey-wm "niri" :onmedia "workspace" "toggle" "media")) 0)
  (test (asked "niri") @["niri msg action focus-workspace-previous"])
  # hyprland has its own idea of a toggle, in Lua; defer to it so the bar and
  # the keybind agree.
  (fresh)
  (test (first (hey-wm "hyprland" "workspace" "toggle" "media")) 0)
  (test (asked "hyprctl") @[`hyprctl eval hey.dsp.scratchpad("media")()`])
  (test (first (hey-wm "niri" "workspace" "toggle" "nope")) 127))

(deftest wm/workspace-move
  (def origin (hey/path/join scratch "hey/vars.d/wm.origin.7"))
  (hey/ignore-errors (os/rm origin))
  # Into media from HDMI-A-1's workspace (id 3), remembering where from.
  (fresh)
  (test (first (hey-wm "niri" :onhdmi "workspace" "move" "media")) 0)
  (test (asked "niri") @["niri msg action move-window-to-workspace --window-id 7 --focus true media"])
  (test (hey/path/file? origin) true)
  # And back out to 3, not to media's own output's first workspace.
  (fresh)
  (test (first (hey-wm "niri" :onmedia "workspace" "move" "media")) 0)
  (test (asked "niri") @["niri msg action move-window-to-workspace --window-id 7 --focus true 3"])
  (test (hey/path/file? origin) false)
  # Nothing remembered (a window that opened on media): the output's first
  # unnamed workspace is the best guess.
  (fresh)
  (test (first (hey-wm "niri" :onmedia "workspace" "move" "media")) 0)
  (test (asked "niri") @["niri msg action move-window-to-workspace --window-id 7 --focus true 1"]))

(deftest wm/set-monitors
  # Enable what's named, disable the rest; placeholders aren't the rest.
  (fresh)
  (test (first (hey-wm "niri" "set-monitors" "DP-1")) 0)
  (test (asked "niri") @["niri msg output DP-1 on" "niri msg output HDMI-A-1 off"])
  (fresh)
  (test (first (hey-wm "niri" "set-monitors" "--off" "HDMI-A-1")) 0)
  (test (asked "niri") @["niri msg output HDMI-A-1 off"])
  (fresh)
  (test (first (hey-wm "niri" "set-monitors" "--on" "HDMI-A-1")) 0)
  (test (asked "niri") @["niri msg output HDMI-A-1 on"])
  # hyprland needs the mode back, which is why it has monitors in hey.info.
  (fresh)
  (test (first (hey-wm "hyprland" "set-monitors" "DP-1")) 0)
  (test (asked "hyprctl")
        @[`hyprctl eval hl.monitor({ output = "DP-1", scale = 1, disabled = false })`
          `hyprctl eval hl.monitor({ output = "HDMI-A-1", scale = 1, disabled = true })`])
  (test (first (hey-wm "niri" "set-monitors")) 127))

(deftest wm/actions
  (fresh)
  (test (first (hey-wm "niri" "dpms" "off")) 0)
  (test (first (hey-wm "niri" "overview")) 0)
  (test (first (hey-wm "niri" "overview" "all")) 0)
  (test (asked "niri") @["niri msg action power-off-monitors"
                        "niri msg action toggle-overview"
                        "niri msg action toggle-overview"])
  (fresh)
  (test (first (hey-wm "hyprland" "dpms" "off")) 0)
  (test (first (hey-wm "hyprland" "overview" "all")) 0)
  (test (asked "hyprctl") @[`hyprctl eval hl.dispatch(hl.dsp.dpms({ action = "disable" }))`
                           `hyprctl eval hey.plugins.so.overview("toggle all", 0.4)()`])
  (test (first (hey-wm "niri" "dpms" "sideways")) 127))

(deftest wm/rate
  # Only Supersonic gets rated. hyprland's fixture has it focused; niri's has
  # foot, so there the key is a no-op rather than a stray `supersonic` call.
  (fresh)
  (test (first (hey-wm "hyprland" "rate" "3")) 0)
  (test (first (hey-wm "niri" "rate" "3")) 0)
  (test (asked "supersonic") @["supersonic -rate-current 3"])
  (test (first (hey-wm "niri" "rate" "6")) 127))

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
