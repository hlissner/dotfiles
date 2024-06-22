#!/usr/bin/env zsh
# Toggle screen zoom.
#
# SYNOPSIS:
#   toggle-zoom [SCALE]
#
# DESCRIPTION:
#   When you gotta see, but things are too dang small. Or you want to point out
#   something to someone. Who knows.
#
#   SCALE defaults to 2.0 if omitted.

local scale="${1:-2.0}"
local zoom=$(( $(hyprctl getoption -j cursor:zoom_factor | jq -r .float) ))
zoom=$(( zoom == 1.0 ? zoom * scale : 1.0 ))
exec hyprctl keyword cursor:zoom_factor "$zoom"
