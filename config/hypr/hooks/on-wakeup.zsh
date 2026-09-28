#!/usr/bin/env zsh
# Wakeup from sleep.
#
# SYNOPSIS:
#   hey hook on-wakeup
#
# DESCRIPTION:
#   Triggered by `hey-sleep-hook` (modules/wm/hyprland/default.nix) when the
#   system wakes up from sleep.

hey.toast info "Waking up..."

hey wm play-sound wakeup

# Sessions outlive suspends, so this is the closest thing to a new day. Walks
# the sockets for the same reason on-reload.zsh does.
for sock in ${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/*(/N); do
  hyprctl -i ${sock:t} eval 'hey.ws.compact()' >/dev/null || true
done
