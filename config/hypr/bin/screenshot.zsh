#!/usr/bin/env zsh
# Capture a screenshot to clipboard.
#
# SYNOPSIS:
#   screenshot [all|full|last|region|window|output]
#
# DESCRIPTION:
#   Captures a screenshot with grim (selecting through `hey .slurp`), compresses
#   it with pngquant, then copies it to your clipboard. If you want graphics, use
#   `hey .screendraw` to draw on the screen before calling this script.
#
# ARGUMENTS:
#   1 TARGET
#     all       -- Capture all outputs combined
#     full      -- Capture the focused output
#     last      -- Capture the previous selection.
#     region    -- Select a region interactively (the default).
#     window    -- Select selected window.
#     output    -- Select a monitor.

main() {
  set -eo pipefail
  hey.requires grim pngquant
  local -a args
  case ${1:-region} in
    all) ;;
    full) args=( -o "$(hyprctl activeworkspace -j | jq -r .monitor)" ) ;;
    last|region|window|output) args=( -g "$(hey .slurp $1)" ) ;;
    *) hey.abort "Unknown target: $1" ;;
  esac
  local preview_file=$(hey path runtime screenshot.png)
  if grim "${args[@]}" - | \
       pngquant --strip -s 10 - >$preview_file | \
       wl-copy -t image/png; then
    trap "rm -f $preview_file" EXIT
    hey.toast -i $preview_file info "Screenshot captured" "Copied to clipboard"
  else
    hey.toast warn "Aborted"
  fi
}

main $@
