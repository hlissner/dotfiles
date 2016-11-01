#!/usr/bin/env dash

# trap "trap - TERM; kill 0" INT TERM QUIT EXIT

#
PANEL_FIFO=/tmp/panel-fifo
PWD=$(dirname $0)
THEME="hax"
LEMONBAR="$(pgrep -cx lemonbar)"

. $PWD/themes/$THEME.sh

if [ "$#" -eq 0 ]; then
    [ -e "$PANEL_FIFO" ] && rm "$PANEL_FIFO"
    mkfifo "$PANEL_FIFO"

    if [ "$LEMONBAR" -gt 0 ]
    then
        echo "Lemonbar already running"
        exit
    fi

    # Load all lemons (components)
    for comp in $PWD/lemons/*.sh
    do
        echo "INIT: $(basename $comp)"
        . "$comp" > "$PANEL_FIFO" &
    done

    #
    # Bootstrap panel(s)
    #

    $PWD/panel_parse.sh $THEME < "$PANEL_FIFO" | \
        lemonbar \
        -a 32 \
        -g x$PANEL_HEIGHT \
        -f "$PANEL_FONT" \
        -f "$ICON_FONT" \
        -F "$COLOR_DEFAULT_FG" \
        -B "$COLOR_DEFAULT_BG" \
        | sh &

    wait
elif [ -e "$PANEL_FIFO" ] && [ "$LEMONBAR" -gt 0 ]
then
    if [ -f "$PWD/lemons/$1.sh" ]
    then
        . "$PWD/lemons/$1.sh" > "$PANEL_FIFO" &
    fi
fi

