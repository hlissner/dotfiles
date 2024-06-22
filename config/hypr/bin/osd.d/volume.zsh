#!/usr/bin/env zsh
# Volume level controller with an OSD popup.
#
# SYNOPSIS:
#   volume [-i|-o|-p] [[+/-]LEVEL|toggle]
#
# DESCRIPTION:
#   Manipulate input or output volume levels via pamixer, or the volume of any
#   player controllable via playerctl, then follow up with an OSD popup.
#
#   Requires a notification program like mako that supports progress bars.
#
# OPTIONS:
#   -i
#     Affect microphone levels.
#   -o
#     Affect sound output levels.
#   -p
#     Affect any players controllable via playerctl (mainly spotify). Does not
#     support toggle.

zparseopts -E -D -- {o,i}=dev p:=player

case $1 in
  toggle) sound=volume-toggle ;;
  +*)     sound=volume-up     ;;
  -*)     sound=volume-down   ;;

  *) hey.abort $1 ;;
esac

if [[ $player ]]; then
  hey.requires playerctl
  case ${player[2]} in
    spotify) icon="" ;;
    # TODO: Add ncmpcpp/mpd/mpc?
    *) icon=""
  esac
  case $1 in
    toggle) hey.abort "Cannot toggle the player's volume" ;;
    +*) hey.do playerctl -p "${player[2]}" volume $(( ${1#+} / 100.0 ))+ ;;
    -*) hey.do playerctl -p "${player[2]}" volume $(( ${1#-} / 100.0 ))- ;;
  esac
  state=$(playerctl -p "${player[2]}" volume)
  if [[ -z $state ]]; then
    hey.error "Could not read volume from player: ${player[2]}"
    exit 1
  fi
  state=$(( state * 100.0 ))
  app=vol
else
  case $dev in
    -i)
      hey.requires pamixer
      case $1 in
        toggle) hey.do pamixer --default-source -t ;;
        +*)     hey.do pamixer --default-source -i ${1#+}+ ;;
        -*)     hey.do pamixer --default-source -d ${1#-}- ;;
      esac
      state=$(pamixer --default-source --get-volume)
      if [[ $(pamixer --default-source --get-mute) == true ]] || (( state <= 1 )); then
        state=0
        icon=""
      elif (( state > 1 )); then
        icon=""
      fi
      app=mic
      ;;
    -o|'')
      hey.requires pamixer
      case $1 in
        toggle) hey.do pamixer -t ;;
        +*)     hey.do pamixer -i ${1#+} ;;
        -*)     hey.do pamixer -d ${1#-} ;;
      esac
      state=$(pamixer --get-volume)
      if [[ $(pamixer --get-mute) == true ]] || (( state <= 1 )); then
        state=0
        icon=""
      elif (( state > 1 )); then
        icon=""
      fi
      app=vol
      ;;
  esac
fi

hey .osd display \
  -p "$state" \
  -a "$app" \
  -s "$sound" \
  "$icon" "$state"
