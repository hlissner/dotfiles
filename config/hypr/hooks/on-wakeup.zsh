#!/usr/bin/env zsh
# Wakeup from sleep.
#
# SYNOPSIS:
#   hey hook on-wakeup
#
# DESCRIPTION:
#   Triggered by `hey-sleep-hook` (modules/hyprland/noctalia.nix) when the
#   system wakes up from sleep.

hey.toast info "Waking up..."

hey .play-sound wakeup
