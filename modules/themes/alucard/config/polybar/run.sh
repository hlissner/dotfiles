#!/usr/bin/env bash

pkill -u $UID -x polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

polybar main >$XDG_DATA_HOME/polybar.log 2>&1 &
echo 'Polybar launched...'
