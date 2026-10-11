#!/usr/bin/env janet
# Turn the monitors off (or on).
#
# SYNOPSIS:
#   hey wm dpms off|on
#
# DESCRIPTION:
#   Hyprland warns against DPMS from a keybind directly, so hyprland.lua wraps
#   it in a timer; this is for the power menu, where a 200ms sleep in the
#   caller does the same job.
#
# ARGUMENTS:
#   1 STATE
#     off   -- Power the monitors off. Any input wakes them.
#     on    -- Power them back on.

(use hey)
(import hey/wm)

(defcmd dpms [_ state]
  (case state
    "off" (wm/dpms false)
    "on" (wm/dpms true)
    (usage)))
