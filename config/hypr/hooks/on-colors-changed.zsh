#!/usr/bin/env zsh
# When Noctalia has re-rendered its templates.
#
# SYNOPSIS:
#   hey hook on-colors-changed
#
# DESCRIPTION:
#   Noctalia's event, on-hyphen-cased (modules/hyprland/noctalia.nix wires
#   every hook it knows about that way). By now every template --
#   hyprland-colors.lua among them -- has been rewritten. Only fires when the
#   palette actually changed, so there's no start-of-session noise to guard
#   against.
#
#   on-theme-mode-changed is a symlink to this file: light/dark re-renders the
#   same templates.

# I'm using this instead of exec= lines in hyprland.conf so I can ensure these
# aren't run at startup and sequentially (i.e. predictable order, since
# Hyprland's exec= calls are parallelized).
for i in $(hyprctl instances -j | jq -r '.[].instance'); do
  echo "Hyprland: reloading instance $i"
  hey.do hyprctl -i ''${i//*\//} reload config-only
done
