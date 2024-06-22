#!/usr/bin/env zsh
# React to changes in the battery's state.
#
# SYNOPSIS:
#   on-battery --discharging
#   on-battery --charging
#   on-battery [--low|--normal|--high|--full|--critical|--poll] STATUS CHARGE REMAINING
#
# DESCRIPTION:
#   TODO

case $1 in
  --discharging)
    hyprctl --batch \
      keyword decoration:blur:enabled false \; \
      keyword decoration:drop_shadow false

    if (( $+commands[brightnessctl] )); then
      if (( ($(brightnessctl get) / $(brightnessctl max).0) > 0.2 )); then
        brightnessctl -m -s set 20%
      fi
    fi
    hey .osd toggle --off "" "Disconnected from power"
    ;;

  --charging)
    hyprctl --batch \
      keyword decoration:blur:enabled true \; \
      keyword decoration:drop_shadow true

    if (( $+commands[brightnessctl] )); then
      brightnessctl -m -r
    fi
    hey .osd toggle --on "" "Reconnected to power"
    ;;

  --critical)
    hey .osd display \
      -a toggle \
      -s battery-low \
      -p 100 \
      -u critical \
      "" "$remaining"
    ;;

  # Intentionally no-op
  --low) ;;
  --normal) ;;
  --high) ;;
  --full) ;;

  --poll)
    local status=$1
    local charge=$2
    local remaining=$3

    local laststate=$(hey get hypr.hook.on-battery.state)
    local state=

    if (( charge < 10 )); then
      state=critical
      echo 10
    elif (( charge < 25 )); then
      state=low
      echo 30
    elif (( charge < 50 )); then
      state=normal
      echo 1m
    elif (( charge <= 98 )); then
      state=high
      echo 5m
    else
      state=full
      echo 10m
    fi

    if [[ $state != $laststate ]]; then
      hey hook battery --$state "$charge" "$remaining" >/dev/null
      hey set hypr.hook.on-battery.state "$state"
    fi
    ;;
esac
