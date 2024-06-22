#!/usr/bin/env zsh
# Enable given monitors and disable the rest.
#
# SYNOPSIS:
#   set-monitors [--on|--off] [@all|@default|@primary|@tv|[MONITOR...]]

udon.all()     { echo DP-3 HDMI-A-2 DP-2 HDMI-A-1; }
udon.default() { echo DP-3 HDMI-A-2 DP-2; }
udon.primary() { echo HDMI-A-2; }
udon.tv()      { echo HDMI-A-1; }

local -a targets=()
for t in ${@:-@default}; do
  if [[ $t == @* ]]; then
    targets+=( $(udon.${t#@}) )
  else
    targets+=$t
  fi
done

hey wm set-monitors ${targets[@]}
