#!/usr/bin/bash

pgrep panel.sh >/dev/null || exit

FIFO=/tmp/panel-fifo

[[ -f $FIFO ]] || exit
echo "$@" > "/tmp/panel-fifo"
