#!/usr/bin/env zsh
# React to various idle states.
#
# SYNOPSIS:
#   on-idle [--dim|--dpms|--lock|--sleep|--resume]
#
# SYNOPSIS:
#   Triggered when there's a change in idle state, by tools like hypridle,
#   swayidle, etc.

case $1 in
  --dim|'')
    sleep 0.2
    if (( $+commands[brightnessctl] )); then
      brightnessctl -m -s set 10
    else
      # A poor-man's dimmer, for non-laptops.
      # TODO
    fi
    ;;

  --dpms)
    sleep 0.2
    xset dpms force off
    ;;

  --lock)
    loginctl lock-session
    ;;

  --sleep)
    systemctl suspend
    ;;

  --resume)
    if (( $+commands[brightnessctl] )); then
      brightnessctl -m -r
    else
      # TODO
    fi
    sleep 1
    xset dpms force on
    ;;
esac
