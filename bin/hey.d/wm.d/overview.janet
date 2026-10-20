#!/usr/bin/env janet
# Toggle the workspace overview.
#
# SYNOPSIS:
#   hey wm overview
#
# DESCRIPTION:
#   For the bar's workspace widget, which can't do it itself.

(use hey)
(import hey/wm)

(defcmd overview [_ & rest]
  (if (empty? rest) (wm/toggle-overview) (usage)))
