#!/usr/bin/env zsh
# Select a monitor, region, or window with slurp.
#
# SYNOPSIS:
#   slurp [output|region|window] [...]
#
# DESCRIPTION:
#   Extends slurp to more closely mirror slop's interface. Passes all arguments
#   to slurp.

main() {
  hey.requires slurp
  case $1 in
    '') slurp $@ ;;
    output)
      hey set $cache_key "-o ${@:2}"
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
        | jq -s 'add | range(0; length; 4) as $i | .[$i:$i+4]' \
        | jq -r '"\(.[0]),\(.[1]) \(.[2])x\(.[3])"' \
        | slurp -r ${@:2}
      ;;
  esac
}

local cache_key=hypr.slurp.last
if [[ "$1" == last ]]; then
  if ! hey get $cache_key; then
    dms ipc toast error "No previous screenshot selection to retake"
    exit 1
  fi
else
  hey set $cache_key "$(main "$@")"
fi
