#!/usr/bin/env bash

pkill -u $UID -x polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

echo 'Launching Polybar...'
{
    # Delay so polybar is above other windows
    sleep 2

    polybardir="$XDG_DATA_HOME/polybar"
    mkdir -p "$polybardir"
    polybar main >"$polybardir/main.log" 2>&1 &
    polybar meta >"$polybardir/meta.log" 2>&1 &
    polybar date >"$polybardir/date.log" 2>&1 &
} &
