#!/usr/bin/env zsh
# Plays a notification sound.
#
# SYNPOSIS:
#   play-sound NAME
#
# DESCRIPTION:
#   TODO

[[ $(makoctl mode) == dnd ]] && return

hey.requires play

# TODO: Abstract sound library
zparseopts -E -D -F -- v:=volume || exit 1
local file=$(echo $(hey path theme sounds)/$1.{ogg,wav,mp3}(-.N[1]))
if [[ -z $file ]]; then
  hey.error "Unrecognized sound: $1"
  exit 1
fi
hey.do play -q $volume $file &
