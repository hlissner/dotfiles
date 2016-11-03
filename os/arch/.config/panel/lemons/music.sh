#!/usr/bin/env bash

while :
do
    output=$(mpc --format ";%title%;%artist%;%album%")
    if echo $output | grep "^;" 2>&1 >/dev/null
    then
        title=$(echo "$output" | head -1 | cut -d';' -f2)
        artist=$(echo "$output" | head -1 | cut -d';' -f3)
        album=$(echo "$output" | head -1 | cut -d';' -f4)
        seek=$(echo "$output" | awk 'NR==2 {print $3}')
        perc=$(echo "$output" | awk 'NR==2 {print $4}' | tr -d '()')
        state=$(echo "$output" | awk 'NR==2 {print $1}')

        case "$state" in
            "[playing]") echo -n "SP" ;;
            "[paused]") echo -n "Sp" ;;
            *) echo -n "S " ;;
        esac

        echo "$title^$artist^$album^$seek^$perc"
    else
        echo "S"
    fi
    sleep 1
done
