#!/usr/bin/env bash

if [[ $# = 0 ]]
then
    data=$(amixer get Master)
    vol=$(echo "$data" | sed -n 's/^.*\[\([0-9]\+\)%.*$/\1/p' | uniq)
    state=$(echo "$data" | grep '\[on\]')
    [[ $state ]] && echo $vol || echo 0
    exit
fi

COMMAND=$1
case "$COMMAND" in
    [0-9]*) amixer set Master $COMMAND ;;
    [+-])   amixer set Master 10%$COMMAND ;;
    *mute)  amixer set Master $COMMAND ;;
    toggle) amixer set Master toggle ;;
    *)  >&2 echo "Invalid command"
        exit 1
        ;;
esac

# Report to lemonbar, if active
~/.config/panel/panel_update.sh volume
