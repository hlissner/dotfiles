#!/usr/bin/env zsh
# When the device is plugged in or unplugged.
#
# SYNOPSIS:
#   hey hook onBatteryPluggedInChanged {plugged-in,on-battery}
#
# SYNOPSIS:
#   Triggered by Dank Actions plugin when the power adapter status has changed.

case "$1" in
  plugged-in)
    hey .play-sound power-on &
    ;;
  on-battery)
    hey .play-sound power-off &
    ;;
esac
