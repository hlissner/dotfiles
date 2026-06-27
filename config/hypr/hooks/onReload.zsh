#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload
#
# SYNOPSIS:
#   Triggered by 'hey reload'

# I'm using this instead of exec= lines in hyprland.conf so I can ensure these
# aren't run at startup and sequentially (i.e. predictable order, since
# Hyprland's exec= calls are parallelized).
for i in $(hyprctl instances -j | jq -r '.[].instance'); do
  echo "Hyprland: reloading instance $i"
  hey.do hyprctl -i ''${i//*\//} reload config-only
done
