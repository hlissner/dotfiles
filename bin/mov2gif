#!/bin/sh

if [ ! -f "$1" ]; then
    >&2 echo "Movie file doesn't exist!"
    exit
fi

palette="/tmp/palette.png"
flags="fps=${4:-10},scale=${3:-640}:-1:flags=lanczos"

ffmpeg -v warning -i "$1" -vf "$flags,palettegen" -y "$palette"
ffmpeg -v warning -i "$1" -i "$palette" -lavfi "$flags [x]; [x][1:v] paletteuse" -y "$2"

[ -f "$palette" ] && rm -f "$palette"
