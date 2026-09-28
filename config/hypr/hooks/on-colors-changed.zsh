#!/usr/bin/env zsh
# When Noctalia has re-rendered its templates.
#
# SYNOPSIS:
#   hey hook on-colors-changed
#
# DESCRIPTION:
#   Noctalia's event, on-hyphen-cased (modules/wm/noctalia.nix wires every hook
#   it knows about that way). By now every template -- hyprland-colors.lua among
#   them -- has been rewritten. Only fires when the palette actually changed, so
#   there's no start-of-session noise to guard against.
#
#   on-theme-mode-changed is a symlink to this file: light/dark re-renders the
#   same templates.

./on-reload.zsh "$@"
