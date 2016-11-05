#!/usr/bin/env bash

shopt -s nullglob globstar

desktops=($(cat /tmp/bspwm-monitor-*))
desktop=$(printf '%s\n' "${desktops[@]}" | rofi -dmenu -p bspwm: "$@")

[[ -n $desktop  ]] || exit

bspc desktop -f $desktop
