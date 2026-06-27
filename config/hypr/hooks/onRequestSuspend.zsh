#!/usr/bin/env zsh
# Suspend event triggered
#
# SYNOPSIS:
#   hey hook onRequestSuspend
#
# SYNOPSIS:
#   Triggered by Dank Actions plugin when the system is put to sleep.

hey .play-sound shutdown
playerctl -a pause
sleep 1
