#!/usr/bin/env bash

while :
do
    echo "V$(volume.sh)" > "$PANEL_FIFO" &
    sleep 3
done > "$PANEL_FIFO" &
