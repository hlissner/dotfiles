#!/usr/bin/env zsh
# Show an on-screen display (w/ volume/brightness control)
#
# SYNOPSIS:
#   osd COMMAND [ARGS...]
#
# DESCRIPTION:
#   Presents an on-screen display to indicate the status of some feature,
#   typically screen brightness and volume control. Can also be used as a more
#   general OSD display command.
#
# DEPENDENCIES:
#   notify-send
#
# OPTIONAL DEPENDENCIES:
#   pamixer, playerctl   -- for osd.d/volume.zsh
#   brightnessctl        -- for osd.d/brightness.zsh

hey.osd.display() {
  zparseopts -E -D -F -- \
    p:=value P=stay a:=app s:=sound {u,t,i}:=pass h+:=hints \
    || return 1
  local p=${value[2]:-0}
  local a=${app[2]:-hey}
  hey.do notify-send \
      -a OSD \
      ${pass[@]} \
      ${hints[@]} \
      ${stay:+--expire-time=999999999} \
      -h string:x-canonical-private-synchronous:osd \
      -h string:category:$a \
      -h "int:value:${value[2]:-0}" \
      "${${@:2}:--}" "<span alpha='$(printf "%d" $(( p >= 80 ? 100 : p + 20 )))%'>$1</span>"
  [[ -n $sound ]] && hey .play-sound -v 0.7 "${sound[2]}"
}

case $1 in
  display) hey.osd.display ${@:2} ;;

  *) hey.abort "Unknown command: $1" ;;
esac
