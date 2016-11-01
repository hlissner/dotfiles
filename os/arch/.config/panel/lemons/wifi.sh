#!/usr/bin/env bash

wifioff="\ue21a"
wifi0="\ue25d"
wifi1="\ue25e"
wifi2="\ue25f"
wifi3="\ue260"
wifi4="\ue261"

while :
do
    signal=$(awk 'NR==3 {print $3}' /proc/net/wireless)
    if [ -n "$signal" ]
    then
        icon=$wifi0
        case "$signal" in
            100|[6-9][0-9]*) icon=$wifi4 ;;
            [4-5][0-9]*) icon=$wifi3 ;;
            [2-3][0-9]*) icon=$wifi2 ;;
            *) icon=$wifi1 ;;
        esac
        echo "I$icon $(iwgetid -r)"
    else
        echo "I%{F$COLOR_FREE_FG}${wifioff}%{F-} "
    fi
    sleep 5
done
