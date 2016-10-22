#!/usr/bin/bash

FIFO=/tmp/panel-fifo

if [[ ! -p $FIFO ]]
then
    >&2 echo "FIFO not initialized"
    exit
fi

echo "$@" > "$FIFO" &
