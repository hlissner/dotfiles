#!/usr/bin/env cached-nix-shell
#! nix-shell -i zsh -p wlrctl libinput.bin
# Cookie clicker didn't stand a chance.
#
# SYNOPSIS:
#   autoclicker [-d MS] [-b BUTTON] [start]
#   autoclicker stop
#
# DESCRIPTION:
#   Uses wlrctl. If you're in the 'input' group, a real click (or ESC) will stop
#   the autoclicker.
#
# OPTIONS:
#   -d MS
#     Milliseconds between clicks. The default of 20 is as fast as Cookie
#     Clicker will count them anyway.
#   -b BUTTON
#     left (the default), right, middle, side, extra, forward, or back.
#
# ARGUMENTS:
#   1 ACTION
#     start -- Start clicking, in the background, until stopped. The default.
#     stop  -- Stop it now, rather than reaching for the mouse.

zmodload zsh/datetime

local -a o_delay o_button
zparseopts -E -D -F -- d:=o_delay b:=o_button || exit 1

local action=${1:-start}
if [[ $action != (start|stop) ]]; then
  hey.error "Expected 'start' or 'stop', got: $action"
  exit 2
fi

local delay=${o_delay[2]:-20}
local button=${o_button[2]:-left}
[[ $delay == <1-> ]] || hey.abort "-d wants milliseconds, got: $delay"
[[ $button == (left|right|middle|side|extra|forward|back) ]] ||
  hey.abort "-b wants a button name, got: $button"

local pidfile=${XDG_RUNTIME_DIR:-/run/user/$UID}/hey/autoclicker.pid

_stop() {
  [[ -r $pidfile ]] && kill $(<$pidfile) 2>/dev/null
  rm -f $pidfile
}

_click() {
  coproc libinput debug-events --show-keycodes 2>/dev/null
  local watcher=$! line
  trap "kill $watcher 2>/dev/null; rm -f $pidfile" EXIT
  trap 'exit 0' TERM INT HUP

  # Don't start clicking until there's a way to make it stop!
  if ! read -t 3 -r -p line; then
    hey.error "libinput isn't watching /dev/input; not in the input group?"
    exit 1
  fi

  local next=$EPOCHREALTIME
  while wlrctl pointer click $button; do
    (( next += delay / 1000.0 ))
    # Doubles as the sleep. If wlrctl falls behind, this degrades to -t 0, which
    # still drains the backlog, so a click always gets noticed.
    while read -t $(( next > EPOCHREALTIME ? next - EPOCHREALTIME : 0 )) -r -p line; do
      [[ $line == *(POINTER_BUTTON|KEY_ESC)*' pressed'* ]] && exit 0
    done
    kill -0 $watcher 2>/dev/null || exit 1
  done
}

case $action in
  start)
    _stop
    mkdir -p ${pidfile:h}
    ( _click ) &!
    print $! >$pidfile
    hey.echo "Clicking $button every ${delay}ms. Click or press Escape to stop."
    ;;
  stop)
    _stop
    hey.echo "Stopped."
    ;;
esac
