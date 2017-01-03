#!/usr/bin/env bash
set -e

# A helper script for bspwm; makes the act of switching and swapping nodes act more
# intuitive.

if (( $# < 2 )); then
    >&2 echo "Usage: $0 [fFsS] DIRECTION"
    exit 1
fi

cmd=$1
dir=$2

case $cmd in
    # focus
    f) if ! bspc node -f "$dir.local"; then
           if [[ $(bspc query -M -m "$dir") ]]; then
               bspc monitor -f "$dir"
           fi
       fi
       ;;

    # focus monitor
    F) bspc monitor -f "$dir" ;;

    # swap
    s) old_id=$(bspc query -N -n focused)
       if bspc node -s "$dir.local"; then
           bspc node -f "$old_id"
       elif [[ $(bspc query -M -m "$dir") ]]; then
           bspc node -m "$dir"
           bspc node -f "$old_id"
       fi
       ;;

    # swap to monitor
    S) old_id=$(bspc query -N -n focused)
       if [[ $(bspc query -M -m "$dir") ]]; then
           bspc node -m "$dir"
           bspc node -f "$old_id"
       fi
       ;;
esac
