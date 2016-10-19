#!/usr/bin/env dash

# Quit if already running
if [ $(pgrep -cx "$(basename $0)") -gt 1 ]
then
    echo "Lemonbar already running"
    exit 1
fi

PWD=$(dirname $0)

. $PWD/scripts/config.sh

trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

# Bootstrap
[ -e "$PANEL_FIFO" ] && rm "$PANEL_FIFO"
mkfifo "$PANEL_FIFO"

#
bspc config top_padding "$PANEL_HEIGHT"
bspc subscribe report > "$PANEL_FIFO" &
clock -sf 'T%A, %b %d::%I:%M %p' > "$PANEL_FIFO" &

for comp in $PWD/lemons/*.sh
do
    echo "INIT: $(basename $comp)"
    . "$comp"
done

$PWD/scripts/parse.sh < "$PANEL_FIFO" | \
    lemonbar \
    -a 32 \
    -g x$PANEL_HEIGHT \
    -f "$PANEL_FONT" \
    -f "$ICON_FONT" \
    -F "$COLOR_DEFAULT_FG" \
    -B "$COLOR_DEFAULT_BG" \
    | sh &

wait
