#!/usr/bin/env zsh
# Executed at shutdown
#
# SYNOPSIS:
#   hey hook on-timer-elapsed
#
# DESCRIPTION:
#   Triggered by my Noctalia Timer plugin.

hey wm play-sound alarm-clock-elapsed
notify-send -a Noctalia -u critical "Timer elapsed!"
