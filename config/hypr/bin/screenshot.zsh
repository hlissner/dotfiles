#!/usr/bin/env zsh
# Capture a screenshot to clibpoard.
#
# SYNOPSIS:
#   screenshot [last|region|window|output]
#
# DESCRIPTION:
#   Captures a screenshot using `dms screenshot`, but compresses it with
#   pngquant before copying it to your clipboard. If you want graphics, use `hey
#   .screendraw` to draw on the screen before calling this script.
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
  hey.requires pngquant
  local preview_file=$(hey path runtime screenshot.png)
  if dms screenshot --no-file --no-clipboard --stdout ${1:-region} | \
       pngquant --strip -s 10 - >$preview_file | \
       wl-copy -t image/png; then
    trap "rm -f $preview_file" EXIT
    dms notify "Screenshot captured" "Copied to clipboard" \
      --icon $preview_file \
      --file $preview_file
  else
    dms ipc toast warn "Aborted"
  fi
}

main $@
