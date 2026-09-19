#!/usr/bin/env zsh
# When matugen completes generating from templates.
#
# SYNOPSIS:
#   hey hook onMatugenCompleteda <mode>:<result>
#   hey hook onMatugenCompleteda dark:success
#   hey hook onMatugenCompleteda light:no-changes
#
# SYNOPSIS:
#   Triggered by Dank Actions plugin when Matugen is finished generating its
#   files.

# Always triggered first thing at startup. Noop just that once.
if (( $(date +%s) - $(hyprctl instances -j | jq '[.[].time] | max // 0') < 30 )); then
  exit 0
fi

dms ipc toast info "Matugen: completed generating files"

for i in $(hyprctl instances -j | jq -r '.[].instance'); do
  echo "Hyprland: reloading instance $i"
  hey.do hyprctl -i ''${i//*\//} reload config-only
done
