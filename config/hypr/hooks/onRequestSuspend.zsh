#!/usr/bin/env zsh
# Suspend event triggered
#
# SYNOPSIS:
#   hey hook onRequestSuspend
#
# SYNOPSIS:
#   Triggered by Dank Actions plugin when the system is put to sleep.

playerctl -a pause
hey .play-sound shutdown
