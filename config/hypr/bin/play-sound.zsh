#!/usr/bin/env zsh
# Plays a notification sound.
#
# SYNPOSIS:
#   play-sound NAME
#
# DESCRIPTION:
#   TODO

if (( $# == 0 )); then
  hey.error "Name of sound required"
  exit 2
fi

local dir=$(hey path theme sounds)
if [[ "$1" == "ls" ]]; then
  ls -l "$dir"
else
  [[ $(makoctl mode) == dnd ]] && return
  hey.requires play
  zparseopts -E -D -F -- v:=volume || exit 1
  local file=$(echo "$dir"/$1.{ogg,wav,mp3}(-.N[1]))
  if [[ -z $file ]]; then
    hey.error "Unrecognized sound: $1"
    exit 1
  fi
  hey.do play -q $volume $file &
fi
