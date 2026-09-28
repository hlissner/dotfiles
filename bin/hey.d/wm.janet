#!/usr/bin/env janet
# Dispatch to config/$WM/bin.
#
# SYNOPSIS:
#   hey wm COMMAND [ARGS...]
#
# DESCRIPTION:
#   The commands below are compiled into hey, for things a keybind or hook fires
#   often enough that a zsh startup would be most of what they cost. Anything
#   else is a script in config/$WM/bin.

(use hey)

(import ./wm.d/play-sound)

(defcmd [wm :rules] [& _]
  [:play-sound play-sound/play-sound
   # Asking for the desktop's scripts on a machine with no desktop is a
   # sentence, not a backtrace.
   {:exec |[(try (path :wm "bin") ([e] (abort "%s" e))) ;$&]}])
