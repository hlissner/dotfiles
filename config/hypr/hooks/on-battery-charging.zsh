#!/usr/bin/env zsh
# When the device is plugged in.
#
# SYNOPSIS:
#   hey hook on-battery-charging
#
# DESCRIPTION:
#   Noctalia splits this from on-battery-discharging, so the argument the two
#   used to share is now the file name.

hey .play-sound power-on &
