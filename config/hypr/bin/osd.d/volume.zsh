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
#     Affect any players controllable via playerctl. Does not support toggle.

zparseopts -E -D -- p:=player

local command=()
case $1 in
  mute)    command=( mute )      ;;
  micmute) command=( micmute )   ;;
  +*)      command=( increment 5 ) ;;
  -*)      command=( decrement 5 ) ;;

  *) hey.abort $1 ;;
esac

hey.do dms ipc call audio ${command[@]}
