#!/usr/bin/env zsh
# Capture (and edit) a screenshot to clibpoard.
#
# SYNOPSIS:
#   screen-capture [last|region|window|output]
#
# DESCRIPTION:
#   Captures a screenshot and sends it to satty.
#
#   The region selection in `dms screenshot` seemed slow, so I prefer the
#   slurp+grim+swappy stack.

main() {
  set -eo pipefail
  hey.requires slurp grim swappy pngquant
  wl-copy --clear  # don't process PNGs already in clipboard
  # ppm is fastest. I leave it to swappy to generate an optimized png
  if grim -t ppm -g "$(hey .slurp ${1:-region})" - | swappy -f -; then
    if [[ "$(wl-paste --list-types | grep -Fx 'image/png')" ]]; then
      if wl-paste --type image/png \
        | pngquant -Q 90-95 -s 1 -f - \
        | wl-copy --type image/png; then
        dms ipc toast info "Copied screenshot to clipboard"
      fi
    fi
  else
    dms ipc toast warn "Aborted"
  fi
}

main $@
