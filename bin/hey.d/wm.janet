#!/usr/bin/env janet
# Drive the compositor, whichever it is.
#
# SYNOPSIS:
#   hey wm COMMAND [ARGS...]
#
# DESCRIPTION:
#   The commands below are compiled into hey, to speed up niri keybinds or hey
#   hooks.

(use hey)

(import ./wm.d/fade)
(import ./wm.d/kill)
(import ./wm.d/launch)
(import ./wm.d/media)
(import ./wm.d/ocr)
(import ./wm.d/outputs)
(import ./wm.d/play-sound)
(import ./wm.d/rate)
(import ./wm.d/screencast)
(import ./wm.d/screenshot)
(import ./wm.d/set-monitors)
(import ./wm.d/slurp)
(import ./wm.d/term)
(import ./wm.d/volume)
(import ./wm.d/workspace)

(defcmd [wm :rules] [& _]
  [:fade fade/fade
   :kill kill/kill
   :launch launch/launch
   :media media/media
   :ocr ocr/ocr
   :outputs outputs/outputs
   :play-sound play-sound/play-sound
   :rate rate/rate
   :screencast screencast/screencast
   :screenshot screenshot/screenshot
   :set-monitors set-monitors/set-monitors
   :slurp slurp/slurp
   :term term/term
   :volume volume/volume
   :workspace workspace/workspace
   # Asking for the desktop's scripts on a machine with no desktop is a
   # sentence, not a backtrace.
   {:exec |[(try (path :wm "bin") ([e] (abort "%s" e))) ;$&]}])
