#!/usr/bin/env zsh
# Triggers when the active hyprland submap changes.
#
# SYNOPSIS:
#   hey hook on-submap [SUBMAP]
#
# DESCRIPTION:
#   Triggered from a `keybinds.submap` event in config/hypr/hyprland.lua.

if [[ -n "${1:-}" ]]; then
  hey .play-sound on
else
  hey .play-sound off
fi
