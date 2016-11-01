#!/usr/bin/env bash

muted="\ue202"
speaker="\ue203"

data=$(amixer get Master)
vol=0
if echo "$data" | grep '\[on\]' >/dev/null
then
    vol=$(echo "$data" | sed -n 's/^.*\[\([0-9]\+\)%.*$/\1/p' | uniq)
fi

case "$vol" in
    0) text="%{F$COLOR_FREE_FG}${muted}%{F-}"
       ;;
    *) text="${speaker} ${vol}%"
       ;;
esac
echo "V%{A:volume.sh toggle:} ${text} %{A}"
