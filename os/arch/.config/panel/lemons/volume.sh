#!/usr/bin/env bash

# I expect all volume adjustments to be done through the volume.sh script (in
# os/arch/bin), which will inform lemonbar of changes, so we only need to intialize
# volume once here.

data=$(amixer get Master)
vol=0
if echo "$data" | grep '\[on\]' >/dev/null
then
    vol=$(echo "$data" | sed -n 's/^.*\[\([0-9]\+\)%.*$/\1/p' | uniq)
fi

echo "V$vol"
