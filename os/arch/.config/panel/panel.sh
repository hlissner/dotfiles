#!/usr/bin/env bash

if [[ $1 == "--kill" ]]
then
    pkill -f 'bash .+/panel\.sh'
    exit
fi


CWD="$(cd $(dirname $0) && pwd -P)"
. $CWD/panel_config

#
running() { pgrep -f $1 >/dev/null; }

cleanup() {
    [ -e "$PANEL_FIFO" ] && rm -f "$PANEL_FIFO"
    pkill -P $$
}

#
trap cleanup INT TERM QUIT EXIT
[ -e "$PANEL_FIFO" ] && rm "$PANEL_FIFO"
mkfifo "$PANEL_FIFO"

if running lemonbar
then
    2>&1 echo "Lemonbar already running"
    exit 1
fi


#
# Bootstrap panel(s)
#

clock -sf "T%A, %b %d::%I:%M%p" > "$PANEL_FIFO" &
xtitle -sf 'X%s' > "$PANEL_FIFO" &
bspc subscribe report > "$PANEL_FIFO" &

pushd $CWD/lemons >/dev/null
for lemon in *.sh
do
    echo "INIT: $lemon"
    ./$lemon > "$PANEL_FIFO" &
done
popd >/dev/null

#
progress-bar() {
    BAR_SIZE=${2:-26}
    C1="%{F#FF0000}-%{F-}"
    C2="%{F#555555}-%{F-}"
    DELIM="%{F#777777}|%{F-}"

    echo "$1" | SIZE=$BAR_SIZE CHAR1="$C1" CHAR2="$C2" SEP='' START="$DELIM" END="$DELIM" mkb
}

parse() {
    num_mon=$(bspc query -M | wc -l)
    while read -r line
    do
        data="${line#?}"
        case $line in
            # Minimal icons
            U*) updates=" %{F${COLOR[DIM]}}\ue00f%{F-}"
                if [[ "$data" > 0 ]]; then
                    updates=" %{F${COLOR[2]}}\ue00f$data%{F-}"
                fi
                ;;
            M*) icon="${ICON[mail]}"
                case "$data" in
                    !)  mail="%{F${COLOR[3]}}$icon!%{F-}"
                        ;;
                    [1-9]*)
                        mail="%{F${COLOR[1]}}$icon$data%{F-}"
                        ;;
                    0)  mail="%{F${COLOR[DIM]}}$icon%{F-}"
                        ;;
                esac
                ;;
            V*) case "$data" in
                    0) vol=" %{F${COLOR[DIM]}}${ICON[muted]}%{F-}"
                       ;;
                    *) vol=" ${ICON[speaker]}"
                       ;;
                esac
                ;;

            # Full segments
            I*) # ssid=" ${data#*,}"
                case "${data%,*}" in
                    100|[6-9][0-9]) icon="${ICON[wifi3]} " ;;
                    [2-5][0-9]) icon="${ICON[wifi2]} " ;;
                    # [1-2][0-9]) icon="${ICON[wifi2]} " ;;
                    x) icon="${ICON[wifioff]}" ;;
                    *) icon="${ICON[wifi1]} " ;;
                esac
                wifi=" $icon"
                ;;
            E*) # TODO ethernet
                ;;
            X*) title="$data"
                ;;
            T*) datetime="   ${ICON[date]} ${data%::*}   ${ICON[time]} ${data#*::}"
                ;;
            S*) song=""
                case "$data" in
                    P*) icon="${ICON[play]}" ;;
                    p*) icon="${ICON[pause]}" ;;
                    *)  icon="" ;;
                esac
                if [[ -n $icon ]]
                then
                    info="${data#?}"
                    title=$(echo "$info" | cut -d'^' -f1)
                    artist=$(echo "$info" | cut -d'^' -f2)
                    album=$(echo "$info" | cut -d'^' -f3)
                    seek=$(echo "$info" | cut -d'^' -f4)
                    perc=$(echo "$info" | cut -d'^' -f5)

                    song="%{B${COLOR[ALTBG]}} $icon ${seek%/*} $(progress-bar $perc 24) ${seek#*/}  %{B-}"
                    song="$song  $title - $artist"
                    [[ $album ]] && song="$song ($album)"
                fi
                ;;
            W*) # bspwm's state
                wm=""
                IFS=':'
                set -- $data
                while [[ $# > 0 ]]
                do
                    id=$1
                    name=${id#???}
                    case $id in
                        [mM]*)
                            [[ $num_mon < 2 ]] && shift && continue
                            case $id in
                                m*) # monitor
                                    _FG=$COLOR_MONITOR_FG
                                    _BG=$COLOR_MONITOR_BG
                                    ;;
                                M*) # focused monitor
                                    _FG=$COLOR_FOCUSED_MONITOR_FG
                                    _BG=$COLOR_FOCUSED_MONITOR_BG
                                    ;;
                            esac
                            wm="${wm}%{F$_FG}%{B$_BG}%{A:bspc monitor -f ${id}:} ${name} %{A}%{B-}%{F-}"
                            ;;
                        [fFoOuU]*)
                            case $id in
                                f*) # free desktop
                                    _FG=$COLOR_FREE_FG
                                    _BG=$COLOR_FREE_BG
                                    ;;
                                F*) # focused free desktop
                                    _FG=$COLOR_FOCUSED_FREE_FG
                                    _BG=$COLOR_FOCUSED_FREE_BG
                                    ;;
                                o*) # occupied desktop
                                    _FG=$COLOR_OCCUPIED_FG
                                    _BG=$COLOR_OCCUPIED_BG
                                    ;;
                                O*) # focused occupied desktop
                                    _FG=$COLOR_FOCUSED_OCCUPIED_FG
                                    _BG=$COLOR_FOCUSED_OCCUPIED_BG
                                    ;;
                                u*) # urgent desktop
                                    _FG=$COLOR_URGENT_FG
                                    _BG=$COLOR_URGENT_BG
                                    ;;
                                U*) # focused urgent desktop
                                    _FG=$COLOR_FOCUSED_URGENT_FG
                                    _BG=$COLOR_FOCUSED_URGENT_BG
                                    ;;
                            esac
                            wm="${wm}%{F$_FG}%{B$_BG}%{A:bspc desktop -f ${id#?}:}  ${ICON[$name]:$name}  %{A}%{B-}%{F-}"
                            ;;
                    esac
                    shift
                done
                ;;
        esac
        echo -e \
            "%{l}${wm}${song}" \
            "%{r}${mail}${updates}${vol}${wifi}${datetime} "
    done
}

parse < "$PANEL_FIFO" | \
    lemonbar \
    -a 32 \
    -g x$PANEL_HEIGHT \
    -f "$PANEL_FONT" \
    -f "$ICON_FONT" \
    -F "${COLOR[FG]}" \
    -B "${COLOR[BG]}" \
    | sh &

wait
