#!/usr/bin/env bash

killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done

polybar main >~/.config/polybar/polybar.log 2>&1 &
