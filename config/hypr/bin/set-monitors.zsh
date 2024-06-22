#!/usr/bin/env zsh
# Enable given monitors and disable the rest.
#
# Why not just use the monitor= directives in hyprland.conf? Because it has
# issues with setting default modes for monitors that I want to be disabled at
# startup (like the TV connected to my system).
#
# SYNOPSIS:
#   set-monitors [--on|--off] [OUTPUTS...]
#   set-monitors HDMI-A-1
#
# OPTIONS:
#   --on
#     Only activate the given displays (i.e. don't disable the rest).
#   --off
#     Only deactivate the given displays (i.e. don't enable the rest).

hypr.is-monitor-on() {
  local state=$(hyprctl monitors all -j | jq -r --arg m "$1" '.[] | select(.name == $m) | .disabled')
  hey.log -3 "${0} '$1' == '$state'"
  [[ "$state" == false ]]
}

hypr.set-layout() {
  hey.log -3 "${0} $@"
  zparseopts -E -D -K -- {-on,-off}=mode || exit 1
  local -a to_enable=()
  local -a to_disable=( $(hyprctl monitors all -j | jq -r '.[] | select(.name | test("^Unknown") | not) | .name') )
  for mon in $@; do to_enable+=$mon; done
  to_disable=( ${to_disable:|to_enable} )

  local -a commands=()
  if [[ ${mode[1]} != --off ]]; then
    hey.log -2 "${0} enable: [ ${to_enable[@]} ]"
    for mon in ${to_enable[@]}; do
      commands+=( "${monitors[$mon]}" )
    done
  fi
  if [[ ${mode[1]} != --on ]]; then
    hey.log -2 "${0} disable: [ ${to_disable[@]} ]"
    for mon in ${to_disable[@]}; do
      commands+=( "$mon,disable" )
    done
  fi
  hey.do hyprctl --batch \
    keyword monitor ${(j. \; keyword monitor .)commands} >/dev/null
  [[ -n "$to_enable" ]] && sleep 0.25  # wait for settings to take effect
  for mon in ${to_enable[@]}; do
    # For some reason, hyprctl struggles to turn on some displays the first
    # time, so wlr-randr is needed.
    local output=${mon/,*/}
    if ! hypr.is-monitor-on "$output"; then
      hey.log -3 "wlr-randr: $output"
      hey.do wlr-randr --output "$output" --on
    fi
  done
}

declare -gxA monitors
for m in $(hey info hypr monitors | jq -r '.[] | "\(.output),\(.mode),\(.position),\(.scale)"' 2>/dev/null); do
  hey.log -3 "Found rule: $m"
  monitors[${m/,*/}]=$m
done
if (( $#monitors == 0 )); then
  hey.error "No monitor rules found! Is hey.info.hypr.monitors set?"
  exit 1
fi
hypr.set-layout $@
