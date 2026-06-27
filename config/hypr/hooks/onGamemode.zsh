#!/usr/bin/env zsh
# Display notifications about gamemode's state.
#
# SYNOPSIS:
#   on-gamemode 1
#   on-gamemode 0
#
# DESCRIPTION:
#   Display a notification indicating the status of gamemode. This ought to be
#   triggered by gamemode's start/end hooks.
#
#   @see modules/desktop/apps/steam.nix.

case $1 in
  on)
    # systemctl start --user gamemoded.service
    echo "Started gamemode..."
    hey.do hyprctl --batch \
      keyword decoration:blur:enabled 0 \; \
      keyword decoration:shadow:enabled 0 \; \
      keyword general:allow_tearing 1 \; \
      keyword animations:enabled 0 \; \
      keyword misc:vrr 1
    dms ipc toast warn "Gamemode started!"
    ;;
  off)
    echo "Stopped gamemode..."
    hey.do hyprctl --batch \
      keyword decoration:blur:enabled 1 \; \
      keyword decoration:shadow:enabled 1 \; \
      keyword general:allow_tearing 0 \; \
      keyword animations:enabled 1 \; \
      keyword misc:vrr 0
    dms ipc toast info "Gamemode ended!"
    # { sleep 3; systemctl stop --user gamemoded.service; }
    ;;
esac
