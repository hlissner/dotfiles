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
for dir in ${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/*(/N); do
  # Hyprland doesn't reap old, improperly shut down instances...
  local pid=
  [[ -f $dir/hyprland.lock ]] && pid=${${(f)"$(<$dir/hyprland.lock)"}[1]}
  if [[ -z $pid ]] || ! kill -0 $pid 2>/dev/null; then
    echo "Hyprland: dead instance at ${dir:t}"
    continue
  fi

  echo "Hyprland: reloading instance ${dir:t}"
  hey.do hyprctl -i ${dir:t} reload   # config-only won't reach libs/plugins!
done
