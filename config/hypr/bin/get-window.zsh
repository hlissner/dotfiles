#!/usr/bin/env zsh
# Select a window with slurp and get it's hyprctl metadata.
#
# SYNOPSIS:
#   get-window [-w]
#
# DESCRIPTION:
#   TODO

main() {
  local hypr_tree=$(hyprctl clients -j)

  local cond_str
  for id in $(hyprctl monitors -j | jq '.[] | .activeWorkspace.id'); do
    cond_str="${cond_str}${cond_str:+ or }.workspace.id == $id"
  done

  if [[ -z "$1" ]]; then
    local prefix="/tmp/hypr.get-window"
    local out_file=$prefix.tmp
    local error_file=$prefix.err
    echo "$hypr_tree" | jq -r ".[] | select($cond_str)" \
                      | jq -r ".at,.size" | jq -s "add" | jq '_nwise(4)' \
                      | jq -r '"\(.[0]),\(.[1]) \(.[2])x\(.[3])"' \
                      | slurp -r > $out_file 2> $error_file &
    PID=$!
    wait $PID

    local error=$(cat $error_file)
    rm -f $error_file

    local selection=$(cat $out_file)
    rm -f $out_file

    [ -n "$error" ] && main  # invalid box format: null,null nullxnull
  else
    selection=$1
  fi

  if [[ -z "$selection" ]]; then
    hey.error "No selection"
    exit 1
  fi

  local x=$(echo "$selection" | awk -F'[, x]' '{print $1}')
  local y=$(echo "$selection" | awk -F'[, x]' '{print $2}')
  local w=$(echo "$selection" | awk -F'[, x]' '{print $3}')
  local h=$(echo "$selection" | awk -F'[, x]' '{print $4}')

  # Find the window matching the selection
  echo "$hypr_tree" | jq -r ".[] | select(($cond_str) and
                                          .at[0] == $x and .at[1] == $y and
                                          .size[0] == $w and .size[1] == $h)"
}

main "$@"
