#!/usr/bin/env bash

theme="$1"

. $(dirname $0)/themes/${theme}.sh

declare -A ICONS
ICONS[desktop]="\ue1d7"
ICONS[code]="\ue1ec"
ICONS[art]="\ue1c7"
ICONS[web]="\ue26d"
ICONS[chat]="\ue19f"
ICONS[file]="\ue1e1"
ICONS[music]="\ue1a6"
ICONS[misc]="\ue140"

num_mon=$(bspc query -M | wc -l)
while read -r line
do
    data="${line#?}"
    case $line in
        E*) # TODO ethernet
            ;;
        T*) # clock output
            date=" ${data%::*} "
            clock=" ${data#*::} "
            ;;
        I*) # wifi
            wifi=" $data "
            ;;
        M*) # TODO mail
            mail=" \ue1a8 2 "
            ;;
        S*) # TODO current song
            playing=" \ue1a6 ... "
            ;;
        B*) # TODO bluetooth
            bt="\ue00b"
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
                                FG=$COLOR_MONITOR_FG
                                BG=$COLOR_MONITOR_BG
                                ;;
                            M*) # focused monitor
                                FG=$COLOR_FOCUSED_MONITOR_FG
                                BG=$COLOR_FOCUSED_MONITOR_BG
                                ;;
                        esac
                        wm="${wm}%{F${FG}}%{B${BG}}%{A:bspc monitor -f ${id}:} ${name} %{A}%{B-}%{F-}"
                        ;;
                    [fFoOuU]*)
                        case $id in
                            f*) # free desktop
                                FG=$COLOR_FREE_FG
                                BG=$COLOR_FREE_BG
                                ;;
                            F*) # focused free desktop
                                FG=$COLOR_FOCUSED_FREE_FG
                                BG=$COLOR_FOCUSED_FREE_BG
                                ;;
                            o*) # occupied desktop
                                FG=$COLOR_OCCUPIED_FG
                                BG=$COLOR_OCCUPIED_BG
                                ;;
                            O*) # focused occupied desktop
                                FG=$COLOR_FOCUSED_OCCUPIED_FG
                                BG=$COLOR_FOCUSED_OCCUPIED_BG
                                ;;
                            u*) # urgent desktop
                                FG=$COLOR_URGENT_FG
                                BG=$COLOR_URGENT_BG
                                ;;
                            U*) # focused urgent desktop
                                FG=$COLOR_FOCUSED_URGENT_FG
                                BG=$COLOR_FOCUSED_URGENT_BG
                                ;;
                        esac
                        wm="${wm}%{F${FG}}%{B${BG}}%{A:bspc desktop -f ${id#?}:}  ${ICONS[$name]:$name}  %{A}%{B-}%{F-}"
                        ;;
                esac
                shift
            done
            ;;
        U*) # updates
            updates=" \ue00f $data updates "
            ;;
        V*) # volume
            vol="$data"
            ;;
    esac
    echo -e "%{l}${wm}${playing}%{r}${mail} ${wifi} ${date} ${clock} ${bt}${vol}"
done
