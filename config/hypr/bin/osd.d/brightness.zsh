#!/usr/bin/env zsh
# Display brightness controller with an OSD popup.
#
# SYNOPSIS:
#   brightness [[+/-]LEVEL]
#
# DESCRIPTION:
#   Manipulate the screen's brightness level via brightnessctl, then follow up
#   with a chirp and OSD popup.

hey.requires brightnessctl

local sound=
if (( $(brightnessctl max) <= 1 )); then
  hey.error "This display doesn't support brightness control"
  exit 1
fi

case $1 in
  +*) sound=brightness-up ;;
  -*) sound=brightness-down ;;
  *) hey.abort -c $1 ;;
esac

IFS=, read _ _ _ state _ <<(hey.do brightnessctl set "${${1/-}/+}%-${1[1]}" -m)

hey .osd display \
  -s "$sound" \
  -p "${state%%%}" \
  -a lcd \
  "" -
