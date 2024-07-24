#!/usr/bin/env zsh
# Use hyprpicker to grab the color on screen.
#
# SYNOPSIS:
#   picker [FMT]
#
# DESCRIPTION:
#   A thin wrapper around hyprpicker to emit notifications and sounds, so I have
#   more feedback when I use it.

main() {
  hey.requires hyprpicker
  local clr=$(hyprpicker -f"${1:-hex}" -a)
  [[ -z "$clr" ]] && return 1
  hey.do notify-send \
    -a hey.picker \
    -h string:x-canonical-private-synchronous:osd \
    "Copied to clipboard" \
    "$clr"
  hey .play-sound blip
}

main $@
