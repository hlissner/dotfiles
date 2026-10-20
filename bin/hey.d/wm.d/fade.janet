#!/usr/bin/env janet
# Fade the screen to or from black.
#
# SYNOPSIS:
#   hey wm fade out [-d MS] [-c COLOR]
#   hey wm fade in [-d MS] [-c COLOR]
#   hey wm fade kill
#
# DESCRIPTION:
#   Paints a quickshell overlay across every monitor and animates a fade-in/out
#   effect. For pre-shutdown and post-startup scripts (the on-shutting-down and
#   on-suspend hooks). niri has no runtime bind or cursor toggle, so the overlay
#   is all there is: no Escape to abort it, and the cursor stays.
#
#   REQUIRES: quickshell
#
# OPTIONS:
#   -d MS
#     Fade for MS milliseconds (default: 500).
#   -c COLOR
#     Fade to COLOR (default: #000000). Accepts anything QML takes: #rrggbb, a
#     named colour, etc.
#
# ARGUMENTS:
#   1 DIRECTION
#     out   -- Fade to black and hold it there.
#     in    -- Fade back in from black.
#     kill  -- Take the overlay away at once.

(use hey)
(use sh)
(import hey/wm)

(def- namespace "hey-fade")

# The overlay's quickshell config. Inline, so this command is self-contained,
# the same way screencast does its region indicator.
(def- qml ```
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int ms: Number(Quickshell.env("HEY_FADE_MS") || 500)
    readonly property color ink: Quickshell.env("HEY_FADE_COLOR") || "#000000"

    // Starts clear so the surface can map -- and the compositor can run its
    // own layer-open fade -- unseen. The script only asks for black once the
    // surface is up, so quickshell's startup eats none of the fade.
    property real target: 0

    IpcHandler {
        target: "fade"
        function out(): string { root.target = 1; return "out" }
        function restore(): string { root.target = 0; return "in" }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            color: "transparent"
            focusable: false
            mask: Region {}  // an empty region is entirely click-through
            exclusionMode: ExclusionMode.Ignore
            anchors { left: true; right: true; top: true; bottom: true }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "hey-fade"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                anchors.fill: parent
                color: root.ink
                opacity: root.target

                // A Behavior rather than a value-source animation, so
                // opacity keeps its binding and nothing fights it
                // halfway through the fade.
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.ms
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
```)

(def- qmlfile (delay (path :runtime "fade.qml")))
(def- pidfile (delay (path :runtime "fade.pid")))

(defn- running-pid
  "The overlay's pid, if the pidfile names a live quickshell running our QML."
  []
  (when-let [pid (ignore-errors (scan-number (string/trim (slurp (pidfile)))))
             # In case of a stale pidfile with a recycled pid
             cmdline (ignore-errors (slurp (fmt "/proc/%d/cmdline" pid)))]
    (when (string/find (qmlfile) cmdline) pid)))

(defn- stop []
  (when-let [pid (running-pid)]
    ($? kill ,(string pid)))
  (ignore-errors (os/rm (pidfile))))

(defn- start [ms color]
  (os/mkdir (path :runtime))
  (spit (qmlfile) qml)
  (def null (file/open "/dev/null" :w))
  (def proc (os/spawn ["quickshell" "-p" (qmlfile)] :epd
                      (merge (os/environ)
                             {"QS_DISABLE_FILE_WATCHER" "1"
                              "QS_NO_RELOAD_POPUP" "1"
                              "HEY_FADE_MS" (string ms)
                              "HEY_FADE_COLOR" color
                              :out null :err null})))
  (file/close null)
  (spit (pidfile) (string (proc :pid))))

(defn- ipc [fn-name]
  ($? quickshell ipc --pid ,(string (running-pid)) call fade ,fn-name > :null))

# Block until the overlay's surfaces exist. Cold-starting quickshell costs
# ~130ms, so animate nothing before then.
(defn- wait-mapped []
  (var mapped false)
  (loop [_ :range [0 100] :until mapped]
    (set mapped (truthy? (index-of namespace (or (ignore-errors (wm/layers)) []))))
    (unless mapped (os/sleep 0.02)))
  mapped)

(defcmd fade [_ direction &opts ms [-d ms] color [-c color]]
  (unless (index-of direction ["out" "in" "kill"]) (usage))
  (unless (path/find "quickshell") (exit 0))
  (def ms (if ms (or (scan-number ms) (abort "-d wants milliseconds, got: %s" ms)) 500))
  (default color "#000000")
  (def secs (/ ms 1000))
  (case direction
    "out"
    (do (unless (running-pid)
          (stop)  # clear a stale pidfile
          (start ms color)
          (unless (wait-mapped) (exit 0)))
        (ipc "out")
        (os/sleep secs))  # wait for shutdown/suspend to take us to narnia

    "in"
    (if (running-pid)
      (do (ipc "restore")
          (os/sleep secs)
          (stop)))

    "kill"
    (stop)))
