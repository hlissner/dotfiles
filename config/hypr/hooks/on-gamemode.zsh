#!/usr/bin/env zsh
# Display notifications about gamemode's state.
#
# SYNOPSIS:
#   hey hook on-gamemode on
#   hey hook on-gamemode off
#
# DESCRIPTION:
#   Display a notification indicating the status of gamemode. This ought to be
#   triggered by gamemode's start/end hooks.
#
#   `off` also queues gamemoded's own shutdown, a few seconds out, which is why
#   there's a third argument I never type myself: idle-stop.
#
#   @see modules/apps/steam.nix.

case $1 in
  on)
    hey.toast warn "Gamemode started!"
    ;;
  off)
    # HACK: End gamemoded.service once all its clients have disconnected
    #   (killing it now would just restart it).
    systemd-run --user --quiet --collect --on-active=5s "${0:A}" kill
    ;;
  kill)
    # --auto-start=no, or merely asking would start the thing I came to stop.
    if [[ "$(busctl --user --auto-start=no get-property \
             com.feralinteractive.GameMode /com/feralinteractive/GameMode \
             com.feralinteractive.GameMode ClientCount 2>/dev/null)" == "i 0" ]]; then
      hey.toast info "Gamemode ended!"
      systemctl --user stop gamemoded.service
    fi
    ;;
esac
