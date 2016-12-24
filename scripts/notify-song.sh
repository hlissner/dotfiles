#!/usr/bin/env bash

if ! pgrep mpd >/dev/null; then
    >&2 echo "mpd isn't running."
    exit 1
fi

info=$(mpc current)
if [[ -z $info ]]; then
    >&2 echo "nothing is playing."
    exit
fi

notify-send --icon="media-playback-start" --app-name="ncmpcpp" "Now playing" "$info"
