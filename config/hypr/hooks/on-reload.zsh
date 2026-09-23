#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload @hypr
#
# DESCRIPTION:
#   Reloads your hyprland config across all known instances of Hyprland.

# Done so that, no matter the context, this command will find your hyprland
# instances. No silly "what instance are you talking about" dance (and `hyprctl
# instances` on 0.56 can report an empty list, so use the socket directly).
for sock in ${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/*(/N); do
  echo "Hyprland: reloading instance ${sock:t}"
  hey.do hyprctl -i ${sock:t} reload   # config-only won't reach libs/plugins!
done
