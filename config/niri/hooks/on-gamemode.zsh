#!/usr/bin/env zsh
# Display notifications about gamemode's state.
#
# SYNOPSIS:
#   hey hook on-gamemode on
#   hey hook on-gamemode off
#
# DESCRIPTION:
#   Display a notification indicating the status of gamemode. This ought to be
#   triggered by gamemode's start/end hooks. Also switches Noctalia's
#   performance-plus plugin on for the duration: toggles Noctalia functionality
#   while games are running, like widgets, wallpaper, DND,
#   animations/blurs/shadows, power profiles, etc. Also truly kills the gamemode
#   daemon on shutdown.
#
#   @see modules/games/steam.nix.
#   @see modules/wm/noctalia.nix for the plugin's settings.

local plugin=detluck/performance-plus:service
case $1 in
  on)
    hey.toast -i device-gamepad-2 warn "Gamemode started!"
    noctalia msg plugin $plugin all enable &>/dev/null
    ;;
  off)
    noctalia msg plugin $plugin all disable &>/dev/null
    # HACK: End gamemoded.service once all its clients have disconnected
    #   (killing it now would just restart it).
    systemd-run --user --quiet --collect --on-active=5s "${0:A}" kill
    ;;
  kill)
    # --auto-start=no, or merely asking would start the thing I came to stop.
    if [[ "$(busctl --user --auto-start=no get-property \
             com.feralinteractive.GameMode /com/feralinteractive/GameMode \
             com.feralinteractive.GameMode ClientCount 2>/dev/null)" == "i 0" ]]; then
      hey.toast -i device-gamepad-2 -m info "Gamemode ended!"
      systemctl --user stop gamemoded.service
    fi
    ;;
esac
