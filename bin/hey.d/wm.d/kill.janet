#!/usr/bin/env janet
# SIGKILL the focused window's process.
#
# SYNOPSIS:
#   hey wm kill
#
# DESCRIPTION:
#   For when close-window is being ignored. Kills the pid the compositor
#   reports for the window, so a window whose client is some other process
#   (xwayland-satellite's, say) takes that down instead.

(use hey)
(use sh)
(import hey/wm)

(defcmd kill [_]
  (def pid (get (wm/focused-window) :pid))
  (unless pid (abort "No focused window"))
  (do? $ kill -9 ,(string pid)))
