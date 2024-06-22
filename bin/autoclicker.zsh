#!/usr/bin/env zsh
# Cookie clicker didn't stand a chance.

if (( $+commands[xdotool] )); then
  _click() {
    xdotool mousedown 1
    sleep 0.01
    xdotool mouseup 1
    sleep 0.01
  }
elif (( $+commands[ydotool] )); then
  _click() {
    ydotool click --repeat=30 --next-delay=30 0xC0
  }
else
  hey.error "No input backend available (xdotool or ydotool)"
  exit 1
fi

while true; do
  _click
done
