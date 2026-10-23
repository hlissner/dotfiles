#!/usr/bin/env zsh
# Wakeup from sleep.
#
# SYNOPSIS:
#   hey hook on-wakeup
#
# DESCRIPTION:
#   Triggered by `hey-sleep-hook` (modules/wm/default.nix) when the system
#   wakes up from sleep. Nothing to compact here: niri's workspaces are
#   already infinite.

hey wm play-sound wakeup
hey.do loginctl lock-session
