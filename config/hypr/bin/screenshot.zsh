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
  hey.requires slurp grim swappy
  hey.do grim -t ppm -g "$(hey .slurp ${1:-region})" - | swappy -f -
}

main $@
