#!/usr/bin/env zsh
# React to various idle states.
#
# SYNOPSIS:
#   idle [--on|--off] [dpms|lock|sleep]
#
# SYNOPSIS:
#   Triggered when there's a change in idle state. Requires a tool like
#   hypridle, swayidle, etc to call it.

case $2 in
  '')
    case $1 in
      --on)
        sleep 0.2
        if (( $+commands[brightnessctl] )); then
          brightnessctl -m -s set 10
        else
          # A poor man's screen dimmer
          hey set hypr.hook.last-shader "$(hyprshade current)"
          hyprshade on screen-dim
        fi
        ;;
      --off)
        if (( $+commands[brightnessctl] )); then
          brightnessctl -m -r
        else
          local sh="$(hey get hypr.hook.last-shader)"
          if [[ -n "$sh" ]]; then
            hyprshade on "$sh"
          else
            hyprshade off
          fi
        fi
        ;;
    esac
    ;;

  dpms)
    sleep 0.2
    case $1 in
      --on)
        hyprctl dispatch dpms off
        ;;
      --off)
        hyprctl dispatch dpms on
        ;;
    esac
    ;;

  lock)
    case $1 in
      --on) ;;
      --off) ;;
    esac
    ;;

  sleep)
    case $1 in
      --on)
        playerctl -a pause &
        # With nvidia cards, hyprlock suffers from redraw issues (making it
        # appear like it's frozen). This helps a little:
        hyprctl --batch \
          keyword decoration:blur:enabled 0 \; \
          keyword general:allow_tearing 1 \; \
          keyword animations:enabled 0 \; \
          keyword misc:vrr 1
        if ! pidof hyprlock >/dev/null; then
          hey .lock --immediate &
          sleep 2
        fi
      ;;
      --off)
        # HACK: Need to "turn off" the screen in order for hyprland to listen
        #   for keypresses to wake up the display, otherwise, I'll be stuck in
        #   an inescapable black screen. Definitely an upstream bug, but that's
        #   normal for Hyprland.
        {
          hyprctl --batch \
            keyword decoration:blur:enabled 1 \; \
            keyword general:allow_tearing 0 \; \
            keyword animations:enabled 1 \; \
            keyword misc:vrr 0
          sleep 1
          hyprctl dispatch dpms off
        } &
        ;;
    esac
    ;;
esac
