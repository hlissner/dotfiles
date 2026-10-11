#!/usr/bin/env janet
# List the compositor's outputs.
#
# SYNOPSIS:
#   hey wm outputs [--focused] [-r] [KEY...]
#
# DESCRIPTION:
#   Every output as JSON: name, focused, enabled, x, y, width, height, scale,
#   all in logical pixels. Same shape under hyprland and niri, which is the
#   point; a shell script that wants the focused monitor's size asks
#
#     hey wm outputs --focused -r width height
#
#   and gets "2560 1440" back, whatever is running.
#
# OPTIONS:
#   --focused
#     Only the focused output.
#   -r
#     Print the values of KEY... space-separated, one output per line, instead
#     of JSON.
#
# ARGUMENTS:
#   * KEY
#     name  focused  enabled  x  y  width  height  scale

(use hey)
(import hey/wm)

(defcmd outputs [_ & keys &opts focused? --focused raw? -r]
  (def outs (if focused? (filter |($0 :focused) (wm/outputs)) (wm/outputs)))
  (if raw?
    (each o outs
      (print (string/join (map |(string (get o (keyword $0) "")) keys) " ")))
    (echo :json (if focused? (first outs) outs))))
