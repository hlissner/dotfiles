#!/usr/bin/env zsh
# Wakeup from sleep.
#
# SYNOPSIS:
#   hey hook on-wakeup
#
# DESCRIPTION:
#   Triggered by `hey-sleep-hook` (modules/wm/hyprland/default.nix) when the
#   system wakes up from sleep.

# Refresh the ntfy plugin after a suspend (instead of waiting for the poll)
hey.do noctalia msg plugin hey/ntfy:stream all reconnect
