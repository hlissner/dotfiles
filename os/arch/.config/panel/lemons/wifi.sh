#!/usr/bin/env bash

while :
do
    echo "I"$(awk 'NR==3 {print $3}' /proc/net/wireless)
    sleep 5
done > "$PANEL_FIFO" &
