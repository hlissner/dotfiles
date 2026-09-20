#!/usr/bin/env zsh
# Suspend event triggered
#
# SYNOPSIS:
#   hey hook on-suspend
#
# DESCRIPTION:
#   Triggered by `hey-sleep-hook` (modules/hyprland/noctalia.nix) when the
#   system goes to sleep.

hey.toast info "Going to sleep.."
playerctl -a pause

# No point fading here. Something else will trigger it before we get here.
hey .play-sound -w sleep
