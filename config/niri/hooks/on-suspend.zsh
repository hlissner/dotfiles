#!/usr/bin/env zsh
# Suspend event triggered
#
# SYNOPSIS:
#   hey hook on-suspend
#
# DESCRIPTION:
#   Triggered by `hey-sleep-hook` (modules/wm/default.nix) when the
#   system goes to sleep.

hey.do playerctl -a pause &
hey.toast -i moon info "Going to sleep.."
hey wm fade -d 1250 out &
hey wm play-sound -w sleep
wait
niri msg action power-off-monitors
