#!/usr/bin/env zsh
# Cookie clicker didn't stand a chance.
#
# SYNOPSIS:
#   autoclicker [-d MS] [-b BUTTON] [start]
#   autoclicker stop
#
# DESCRIPTION:
#   Uses hyprland timers instead of ydo-tool. Press ESC to kill the autoclicker.
#
# OPTIONS:
#   -d MS
#     Milliseconds between press and release. A full click is two of these, so
#     the default of 15 is about 33 a second.
#   -b BUTTON
#     Which button, as a linux input code: 272 left, 273 right, 274 middle.
#
# ARGUMENTS:
#   1 ACTION
#     start -- Arm it, and leave Escape to disarm it. The default.
#     stop  -- Disarm it now, rather than reaching for Escape.

local -a o_delay o_button
zparseopts -E -D -F -- d:=o_delay b:=o_button || exit 1

local action=${1:-start}
if [[ $action != (start|stop) ]]; then
  hey.error "Expected 'start' or 'stop', got: $action"
  exit 2
fi

(( $+commands[hyprctl] )) || hey.abort "No hyprctl; this one is Hyprland's to do"

local delay=${o_delay[2]:-15}
local button=${o_button[2]:-272}
[[ $delay == <-> ]] || hey.abort "-d wants milliseconds, got: $delay"
[[ $button == <-> ]] || hey.abort "-b wants a linux input code, got: $button"

# hyprctl eval always returns 0, even if the lua fails. Gotta read its output to
# determine the status.
_eval() {  # LUA
  local out=$(hyprctl eval "$1" 2>&1)
  if [[ $out != ok ]]; then
    hey.error "hyprctl eval: ${out:-no answer}"
    return 1
  fi
}

# Since wtype doesn't do mice and I don't like the ydotool daemon, I use
# hyprland's timers and send_key_state dispatcher to simulate high-performance
# mouse clicks. Gotta go fast.
_lua_start() {
  echo 'if _G.__hey_autoclick then _G.__hey_autoclick.stop() end'
  echo 'local A = { down = false, key = "mouse:'$button'" }'
  echo 'A.send = function (state)'
  echo '  hl.dispatch(hl.dsp.send_key_state({ mods = "", key = A.key, state = state }))'
  echo 'end'
  echo 'A.stop = function ()'
  echo '  if A.timer then A.timer:set_enabled(false) end'
  echo '  hl.unbind("escape")'
  echo '  -- Never leave the button held down; that is someone else'"'"'s drag.'
  echo '  if A.down then A.down = false; A.send("up") end'
  echo 'end'
  echo 'A.timer = hl.timer(function ()'
  echo '  A.down = not A.down'
  echo '  A.send(A.down and "down" or "up")'
  echo 'end, { timeout = '$delay', type = "repeat" })'
  echo 'hl.bind("escape", A.stop)'
  echo '_G.__hey_autoclick = A'
}

case $action in
  start)
    _eval "$(_lua_start)" || exit 1
    hey.echo "Clicking mouse:$button every $(( delay * 2 ))ms. Escape stops it."
    ;;
  stop)
    _eval 'if _G.__hey_autoclick then _G.__hey_autoclick.stop() end' || exit 1
    hey.echo "Stopped."
    ;;
esac
