#!/usr/bin/env bash

# volume messages will be sent when volume is changed
echo "V$(amixer get Master | sed -n 's/^.*\[\([0-9]\+\)%.*$/\1/p' | uniq)" > "$PANEL_FIFO" &

# while :
# do
#     echo "V$(amixer get Master | sed -n 's/^.*\[\([0-9]\+\)%.*$/\1/p' | uniq)"
#     sleep 1
# done > "$PANEL_FIFO" &
