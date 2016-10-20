#!/usr/bin/env bash

# initialize volume display (once)
echo "V$(volume.sh)" > "$PANEL_FIFO" &
