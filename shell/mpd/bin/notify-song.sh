#!/usr/bin/env bash

if ! pgrep mpd >/dev/null; then
    >&2 echo "mpd isn't running."
    exit 1
fi

info=$(mpc -f ";%artist%;%album%;%title%")
if [[ -z $info || ${info:0:1} != ";" ]]; then
    >&2 echo "nothing is playing."
    exit
fi

artist=$(awk -F';' '{ print $2 }' <<<"$info")
album=$(awk -F';' '{ print $3 }' <<<"$info")
title=$(awk -F';' '{ print $4 }' <<<"$info")

case $OSTYPE in
    darwin*)
        terminal-notifier -title "$title" -message "by $artist\n$album" -appIcon "/Applications/iTunes.app/Contents/Resources/iTunes.icns"
        ;;
    linux*)
        notify-send --icon="media-playback-start" --app-name="ncmpcpp" "$title" "$artist\n<i>$album</i>"
        ;;
esac
