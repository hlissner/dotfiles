#!/usr/bin/env bash

if ! pgrep mpd >/dev/null; then
    >&2 echo "mpd isn't running."
    exit 1
fi

info=$(mpc -f ";%artist%;%album%;%title%;%file%")
if [[ -z $info || ${info:0:1} != ";" ]]; then
    >&2 echo "nothing is playing."
    exit
fi

artist=$(awk -F';' '{ print $2 }' <<<"$info")
album=$(awk -F';' '{ print $3 }' <<<"$info")
title=$(awk -F';' '{ print $4 }' <<<"$info")
file=$(awk -F';' '{ print $5 }' <<<"$info")

artist="${artist:-No Artist}"
album="${album:-No Album}"
title="${title:-Untitled}"
rating=

stars=$(cd ~/music/.db/playlists/ && grep "$file" ./*-star.m3u)
if [[ $stars ]]; then
    case $stars in
        ./1-star.m3u*) starn=1 ;;
        ./2-star.m3u*) starn=2 ;;
        ./3-star.m3u*) starn=3 ;;
        ./4-star.m3u*) starn=4 ;;
        ./5-star.m3u*) starn=5 ;;
    esac

    if [[ $starn ]]; then
        star_filled_icon="★"
        star_empty_icon="☆"

        for ((i=1;i<=5;i++)); do
            if (( "$starn" >= "$i" )); then
                rating="${rating}${star_filled_icon}"
            else
                rating="${rating}${star_empty_icon}"
            fi
        done
    fi
fi

case $OSTYPE in
    darwin*)
        rating="[$rating] "
        killall terminal-notifier
        terminal-notifier -title "$rating$title" -message "by $artist :: $album" -appIcon "/Applications/iTunes.app/Contents/Resources/iTunes.icns"
        ;;
    linux*)
        notify-send --icon="media-playback-start" --app-name="ncmpcpp" "$title" "${artist}\n<i>${album}</i>\n$rating"
        ;;
esac &
