#!/usr/bin/env zsh
# Select a monitor, region, or window with slurp.
#
# SYNOPSIS:
#   slurp [output|region|window] [...]
#
# DESCRIPTION:
#   Extends slurp to more closely mirror slop's interface. Passes all arguments
#   to slurp.

case $1 in
  '') slurp $@ ;;

  output)
    slurp -o ${@:2}
    ;;
  region)
    slurp ${@:2}
    ;;
  window)
    local cond_str
    for id in $(hyprctl -i 0 monitors -j | jq '.[] | .activeWorkspace.id'); do
      cond_str="${cond_str}${cond_str:+ or }.workspace.id == $id"
    done
    hyprctl clients -j | jq -r ".[] | select($cond_str) | .at,.size" \
                       | jq -s "add | _nwise(4)" \
                       | jq -r '"\(.[0]),\(.[1]) \(.[2])x\(.[3])"' \
                       | slurp -r ${@:2}
    ;;
esac
