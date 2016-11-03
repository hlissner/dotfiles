#!/usr/bin/env bash

if [ "$#" -eq 0 ]
then
    >&2 echo "Usage: panel_update.sh [LEMON_TO_UPDATE]"
    exit 1
fi

CWD=$(cd $(dirname $0) && pwd -P)
LEMON="$CWD/lemons/$1.sh"

if [ ! -f "$LEMON" ]
then
    >&2 echo "Couldn't find that lemon ($1)"
    exit 2
fi

. $CWD/panel_config
pkill -f "bash \./lemons/$1\.sh"
pushd "$CWD" >/dev/null
./lemons/$1.sh > "$PANEL_FIFO" &
popd >/dev/null
