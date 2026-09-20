#!/usr/bin/env zsh
# When the device is unplugged.
#
# SYNOPSIS:
#   hey hook on-battery-discharging
#
# DESCRIPTION:
#   The other half of on-battery-charging.

hey .play-sound power-off &
