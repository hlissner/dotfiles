#!/usr/bin/env janet
# Toggle the workspace overview.
#
# SYNOPSIS:
#   hey wm overview [all]
#
# DESCRIPTION:
#   Hyprland's is the scroll-overview plugin, where `all` zooms out to every
#   workspace; niri's built-in overview always shows them all, so `all` is a
#   no-op there. For the bar's workspace widget, which can't know which.
#
# ARGUMENTS:
#   1 MODE
#     all   -- Every workspace, not just the current one.

(use hey)
(import hey/wm)

(defcmd overview [_ mode]
  (case mode
    nil (wm/toggle-overview)
    "all" (wm/toggle-overview true)
    (usage)))
