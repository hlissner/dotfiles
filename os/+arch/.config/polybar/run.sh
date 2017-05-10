#!/usr/bin/env bash

if pgrep polybar; then
    killall -q polybar
    while pgrep -x polybar >/dev/null; do sleep 1; done
fi

polybar main >>~/.config/polybar/polybar.log 2>&1 &
