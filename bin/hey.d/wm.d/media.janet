#!/usr/bin/env janet
# Jump to the media player's window, and back.
#
# SYNOPSIS:
#   hey wm media
#
# DESCRIPTION:
#   Focuses the window of whatever playerctl says is playing, wherever it is.
#   If it already has the focus, goes back to the window that had it before
#   (remembered in the wm.media.origin var on the way over), or to the previous
#   workspace when there's nothing remembered. For the bar's media widget.
#
#   The player is matched to a window by name: playerctl's playerName
#   ("supersonic") against the window's app-id
#   ("io.github.supersonic-app.supersonic"), case-insensitively.

(use hey)
(use sh)
(import hey/wm)
(import hey/vars)
(import hey/sys)

(def- origin :wm.media.origin)

(defn- player-window []
  (def name (string/ascii-lower (string/trim ($< playerctl metadata --format "{{playerName}}"))))
  (when (empty? name) (abort "Nothing is playing"))
  (or (find |(string/find name (string/ascii-lower (or ($0 :app-id) ""))) (wm/windows))
      (abort "%s has no window" name)))

(defcmd media [_]
  (def w (player-window))
  (if (w :focused)
    (let [back (vars/get origin)]
      (vars/set origin nil)
      (if back
        (wm/action "focus-window" "--id" (string back))
        (wm/action "focus-workspace-previous")))
    (do (vars/set origin (get (wm/focused-window) :id))
        (wm/action "focus-window" "--id" (string (w :id))))))
