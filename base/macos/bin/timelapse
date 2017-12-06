#!/usr/bin/env bash

# Start taking screenshots every N seconds, until this script is
# called again.

if [ ! -f ~/.ss ]; then
    dir="$1"
    if [ $# -eq 0 ]; then
        [ ! -d ~/Desktop/ss ] && mkdir -p ~/Desktop/ss
        dir=~/Desktop/ss
    fi
    echo "$dir" > ~/.ss
    echo "Timelapse, go!"
    i=1;while [ -f ~/.ss ];do screencapture -t jpg -x "$dir/$i.jpg"; let i++;sleep 5; done &
else
    echo "Deactivating timelapse! Images in: $(cat ~/.ss)/"
    rm ~/.ss
fi
