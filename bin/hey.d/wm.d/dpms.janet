#!/usr/bin/env janet
# Turn the monitors off (or on).
#
# SYNOPSIS:
#   hey wm dpms off|on
#
# DESCRIPTION:
#   For the power menu; the caller sleeps 200ms first so the keypress that asked
#   doesn't wake them straight back up.
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
