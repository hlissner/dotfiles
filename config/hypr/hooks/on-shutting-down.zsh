#!/usr/bin/env zsh
# Executed at shutdown
#
# SYNOPSIS:
#   hey hook on-shutting-down
#
# DESCRIPTION:
#   Triggered by Noctalia's power menu, and by hey @rofi powermenu before it
#   calls systemctl. on-rebooting is a symlink to this file; the session dies
#   the same either way. Failing both, hey-shutdown-hook.service catches the
#   session going down on its own (modules/wm/hyprland/default.nix).

local stamp=$(hey path runtime session-ending)
[[ -e $stamp ]] && exit 0
mkdir -p ${stamp:h} && : >|$stamp

hey.toast warn "Shutting down..."

# Fade while the sound plays. Plus the ~130ms quickshell takes to cold-start.
hey .fade -d 1250 out &
hey .play-sound -w shutdown
wait
