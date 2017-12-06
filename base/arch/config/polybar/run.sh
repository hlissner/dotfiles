#!/usr/bin/env zsh

killall -q polybar
while _is_running polybar; do sleep 1; done

source "${0:A:h}/../../bin/inject-xcolors"
pushd ~ >/dev/null
polybar main >>$XDG_DATA_HOME/polybar.log 2>&1 &
popd >/dev/null

echo "Polybar launched..."
