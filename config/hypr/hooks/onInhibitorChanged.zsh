#!/usr/bin/env zsh
# Toggle inhibit idle.
#
# SYNOPSIS:
#   hey hook onInhibitorChanged
#
# SYNOPSIS:
#   Triggered by Dank Actions plugin when idle inhibition is toggled.

case "$1" in
  not-inhibited)
    hey .play-sound off &
    ;;
  inhibited)
    hey .play-sound on &
    ;;
esac
