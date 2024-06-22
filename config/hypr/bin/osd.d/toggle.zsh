#!/usr/bin/env zsh
# Display a toggle OSD.
#
# TODO

hey .osd display \
  -p "${${1//--on/100}//--off/0}" \
  -a indicator \
  -s blip \
  ${@:2}
