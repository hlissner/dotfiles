#!/usr/bin/env bash

if [[ $# == 0 ]]
then
    echo "Usage: volume.sh [+|-|unmute|mute]"
    exit 1
fi

COMMAND=$1
case "$COMMAND" in
    [+-])  amixer set Master 10%$COMMAND ;;
    *mute) amixer set Master $COMMAND ;;
    *)
        echo "Invalid command"
        exit 1
        ;;
esac

# Report to lemonbar, if active
if amixer get Master | grep '\[off\]' >/dev/null
then
    panel_notify.sh "V0"
else
    panel_notify.sh "V$(amixer get Master | sed -n 's/^.*\[\([0-9]\+\)%.*$/\1/p' | uniq)"
fi
