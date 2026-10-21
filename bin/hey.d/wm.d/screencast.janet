#!/usr/bin/env janet
# Record a region of the screen to clipboard.
#
# SYNOPSIS:
#   hey wm screencast [webm|mp4|gif] [TARGET] [DELAY]
#
# DESCRIPTION:
#   Prompts for a region, window, or monitor and records it with wf-recorder.
#   Produces a webm by default, or mp4 or gif. If quickshell is present, a
#   dashed outline marks the recorded region until the recording ends. Running
#   it again while a recording is live stops that recording, which is what the
#   bar's widget does (config/noctalia/plugins/screencast).
#
# DEPENDENCIES:
#   wf-recorder, ffmpeg, quickshell*, gifsicle**
#
#   * Optional: needed for the region indicator
#   ** Is auto-installed by cached-nix-shell if needed.
#
# ARGUMENTS:
#   1 FORMAT
#     webm      -- Optimized for short recordings of text or code (the default).
#     mp4       -- Optimized for high-motion content.
#     gif       -- Produce an animated gif.
#   2 TARGET
#     last      -- Reuse the previous selection.
#     region    -- Select an arbitrary region (the default).
#     window    -- Select a window.
#     output    -- Select a monitor.
#   3 DELAY

(use hey)
(use sh)
(import hey/wm)
(import hey/sys)

# The quickshell config for the region indicator. Inline, to keep this command
# self-contained.
(def- qml ```
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    // The region to outline, in global (compositor) coordinates.
    readonly property real regionX: Number(Quickshell.env("HEY_SCREENCAST_X") || 0)
    readonly property real regionY: Number(Quickshell.env("HEY_SCREENCAST_Y") || 0)
    readonly property real regionW: Number(Quickshell.env("HEY_SCREENCAST_W") || 0)
    readonly property real regionH: Number(Quickshell.env("HEY_SCREENCAST_H") || 0)

    readonly property real thickness: 2
    readonly property color ink: Quickshell.env("HEY_SCREENCAST_COLOR") || "#ff4d4d"

    // Strokes are centered on its path, so the path must sit half a stroke out.
    readonly property real offset: 2 + thickness / 2

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            readonly property real boxLeft: root.regionX - root.offset - modelData.x
            readonly property real boxTop: root.regionY - root.offset - modelData.y
            readonly property real boxRight: boxLeft + root.regionW + root.offset * 2
            readonly property real boxBottom: boxTop + root.regionH + root.offset * 2

            screen: modelData
            // Do not map a surface on monitors the outline cannot reach.
            visible: root.regionW > 0 && root.regionH > 0
                     && boxRight >= 0 && boxBottom >= 0
                     && boxLeft <= modelData.width && boxTop <= modelData.height

            color: "transparent"
            focusable: false
            mask: Region {}  // an empty region is entirely click-through
            exclusionMode: ExclusionMode.Ignore
            anchors { left: true; right: true; top: true; bottom: true }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "screencast-region"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.GeometryRenderer  // dashes need it

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: root.ink
                    strokeWidth: root.thickness
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [4, 3]             // in units of strokeWidth
                    capStyle: ShapePath.FlatCap     // SquareCap would overhang
                    joinStyle: ShapePath.MiterJoin  // miters point outward only

                    startX: win.boxLeft
                    startY: win.boxTop
                    PathLine { x: win.boxRight; y: win.boxTop }
                    PathLine { x: win.boxRight; y: win.boxBottom }
                    PathLine { x: win.boxLeft;  y: win.boxBottom }
                    PathLine { x: win.boxLeft;  y: win.boxTop }

                    NumberAnimation on dashOffset {
                        from: 7
                        to: 0
                        duration: 600
                        loops: Animation.Infinite
                    }
                }
            }
        }
    }
}
```)

# wf-recorder's arguments per format. --audio-backend first, then the codec.
(def- formats
  {"webm" ["-c" "libvpx-vp9" "-x" "yuv444p" "-r" "30"
           # Optimized for short (sub-30s) recordings of text/code. Use mp4 for
           # gaming-quality recordings.
           "-p" "crf=24" "-p" "cpu-used=0" "-p" "deadline=good"
           "-p" "row-mt=1" "-p" "tile-columns=2" "-p" "b=0" "-p" "g=240"]
   "mp4"  ["--audio" "-c" "libx264" "-r" "60" "-B" "60" "-b" "5"
           # Optimized for high-motion (sub-30s) recordings of high-motion
           # content, like games or video.
           "-p" "preset=slow" "-p" "tune=animation" "-p" "crf=18"
           "-p" "g=300" "-p" "keyint_min=60" "-p" "aq-mode=3"
           "-p" "profile=high" "-p" "level=4.2"]
   # Not optimized at all. There really is little reason to use gif over webm,
   # but I keep it here for posterity.
   "gif"  ["--codec" "gif"]})

# The bar widget reads these off `hey path runtime screencast`.
(def- prefix (delay (path :runtime "screencast")))
(def- livefile (delay (string (prefix) ".live")))
(def- qmlfile (delay (string (prefix) ".qml")))
(def- pidfile (delay (string (prefix) ".pid")))

(defn- indicator-stop []
  (when-let [pid (ignore-errors (scan-number (string/trim (slurp (pidfile)))))
             # In case of a stale pidfile with a recycled pid
             cmdline (ignore-errors (slurp (fmt "/proc/%d/cmdline" pid)))]
    (when (string/find (qmlfile) cmdline)
      ($? kill ,(string pid))))
  (ignore-errors (os/rm (pidfile))))

(defn- indicator-start [[x y w h]]
  (when (path/find "quickshell")
    (spit (qmlfile) qml)
    (indicator-stop)  # in case of a SIGKILLed run
    (def null (file/open "/dev/null" :w))
    (def proc (os/spawn ["quickshell" "-p" (qmlfile)] :epd
                        (merge (os/environ)
                               {"QS_DISABLE_FILE_WATCHER" "1"
                                "QS_NO_RELOAD_POPUP" "1"
                                "HEY_SCREENCAST_X" (string x)
                                "HEY_SCREENCAST_Y" (string y)
                                "HEY_SCREENCAST_W" (string w)
                                "HEY_SCREENCAST_H" (string h)
                                :out null :err null})))
    (file/close null)
    (spit (pidfile) (string (proc :pid)))))

(defn- cleanup [&]
  (indicator-stop)
  (each f [(livefile) (qmlfile)]
    (ignore-errors (os/rm f))))

(defcmd screencast [_ format target delay]
  (each dep ["wf-recorder" "ffmpeg"]
    (unless (path/find dep) (abort "Required dependency not met: %s" dep)))
  (os/mkdir (path :runtime))
  # Re-entering while the .live file exists *is* the stop switch.
  (when (path/file? (livefile))
    ($? pkill -SIGINT wf-recorder)
    (indicator-stop)  # instant feedback; don't wait on the muxer
    (os/rm (livefile))
    (break))
  (default format "webm")
  (def opts (or (get formats format) (abort "Unknown format: %s" format)))
  (def file (string (prefix) "." format))
  (ignore-errors (os/rm file))
  (spit (livefile) "")
  (trap cleanup)
  (def geom (or (wm/select (or target "region")) (exit 1)))
  (def box (or (wm/parse-geometry geom) (abort "Unrecognized geometry: %s" geom)))

  # Up before the countdown, so qt is done warming up by frame one.
  (indicator-start box)
  (def delay (if delay (or (scan-number delay) 0) 0))
  (loop [i :down-to [delay 1]]
    (sys/play-sound "blip")
    (sys/toast :warn (fmt "Recording starting in... %d" i)
               :icon "player-record" :progress (/ i delay))
    (os/sleep 1))
  # The bar widget counts up from this.
  (spit (livefile) (string (os/time)))
  (def rc (first (run wf-recorder -g ,geom --audio-backend pipewire ,;opts ,(string "--file=" file))))
  (indicator-stop)  # dies with the recording, not with gifsicle
  (when (zero? rc)
    (os/sleep 0.1)
    (when (= format "gif")
      (sys/toast :warn "Optimizing gif. This may take a while..." :icon "gif")
      ($ cached-nix-shell -p gifsicle --run ,(fmt "gifsicle --optimize=3 %q" file)))
    (sys/yank (string "file://" file) :type "text/uri-list")
    (sys/play-sound "success")
    (sys/toast :info "Recording complete. Copied to clipboard!" :icon "clipboard-check")))
