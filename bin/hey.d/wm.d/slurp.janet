#!/usr/bin/env janet
# Select a monitor, region, or window with slurp.
#
# SYNOPSIS:
#   hey wm slurp [last|output|region|window] [SLURPARGS...]
#
# DESCRIPTION:
#   Extends slurp to more closely mirror slop's interface, and remembers the
#   last selection (as the wm.slurp.last var) so `last` can retake it. Prints
#   "X,Y WxH"; exits 1 when the selection is cancelled.
#
# ARGUMENTS:
#   1 TARGET
#     last      -- Reuse the previous selection.
#     output    -- Select a monitor.
#     region    -- Select an arbitrary region (the default).
#     window    -- Select a window.
#   * SLURPARGS

(use hey)
(import hey/wm)
(import hey/sys)

(defcmd slurp [_ target & args]
  (unless (path/find "slurp") (abort "Required dependency not met: slurp"))
  (if-let [geom (wm/select target ;args)]
    (print geom)
    (do (when (= target "last")
          (sys/toast :error "No previous selection to retake"))
        (exit 1))))
