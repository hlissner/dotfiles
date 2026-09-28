#!/usr/bin/env zsh
# Display notifications about gamemode's state.
#
# SYNOPSIS:
#   hey hook on-gamemode on
#   hey hook on-gamemode off
#
# DESCRIPTION:
#   Display a notification indicating the status of gamemode. This ought to be
#   triggered by gamemode's start/end hooks. Also zeroes decoration.dim_around
#   and hides Noctalia's desktop widgets while gamemode is on.
#
#   `off` also queues gamemoded's own shutdown, a few seconds out, which is why
#   there's a third argument I never type myself: idle-stop.
#
#   @see modules/apps/steam.nix.

case $1 in
  on)
    hey.toast warn "Gamemode started!"
    # Stashed in a Lua global so `off` restores whatever hyprland.lua set, and
    # `or` so a second `on` doesn't stash the 0.
    hyprctl eval 'gamemode_dim_around = gamemode_dim_around or hl.get_config("decoration.dim_around")
                  hl.config({ decoration = { dim_around = 0 } })' &>/dev/null
    # Hiding tears the widgets down, so they stop costing frames, not just
    # pixels. Runtime-only; the saved setting is untouched.
    noctalia msg desktop-widgets-hide &>/dev/null
    ;;
  off)
    hyprctl eval 'if gamemode_dim_around then
                    hl.config({ decoration = { dim_around = gamemode_dim_around } })
                    gamemode_dim_around = nil
                  end' &>/dev/null
    # HACK: -show overrides the saved setting too, so this would resurrect
    #   widgets I'd disabled in Settings. Fine as long as I haven't.
    noctalia msg desktop-widgets-show &>/dev/null
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
