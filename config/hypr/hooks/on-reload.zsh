#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload @hypr
#
# DESCRIPTION:
#   Reloads your hyprland config across all known instances of Hyprland.

# Done so that, no matter the context, this command will find your hyprland
# instances. No silly "what instance are you talking about" dance.
for i in $(hyprctl instances -j | jq -r '.[].instance'); do
  echo "Hyprland: reloading instance $i"
  hey.do hyprctl -i ''${i//*\//} reload config-only
done
