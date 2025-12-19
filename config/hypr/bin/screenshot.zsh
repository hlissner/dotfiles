#!/usr/bin/env zsh
# Capture (and edit) a screenshot to clibpoard.
#
# SYNOPSIS:
#   screen-capture [-e] [-o|--optimize] [-f FILE] [region|window|output]
#
# DESCRIPTION:
#   Captures a screenshot, optionally piping it through swappy, then optimizing
#   it with pngquant, before writing it to the clipboard (or to FILE). Also
#   notifies you once it's complete (with the screenshot as the notification
#   icon).
#
# OPTIONS:
#   -o, --optimize
#     Run pngquant on resulting png.
#   -s, --swappy
#     After capturing the image, invoke swappy on it (for quick editing).
#   -f FILE
#     Write the resulting file to FILE rather than to the clipboard.

main() {
  zparseopts -E -D -F -- {s,-swappy}=swappy f:=dest c:=countdown {o,-optimize}=optimize || return 1
  local file="${dest[2]:-$(hey path runtime screencapture.png)}"
  mkdir -p "$(dirname $file)"
  hey.do dms screenshot \
    -d $(dirname $file) \
    --filename $(basename $file) \
    --no-clipboard ${1:-region} \
    --no-notify

  [[ $dest ]] || trap "rm -f '$file'" EXIT
  if [[ $swappy ]]; then
    hey.do swappy -f "$file" -o "$file" || return 1

    # Provide some feedback that the process is progressing as intended.
    hey .play-sound blip
  fi
  if [[ $optimize ]]; then
    hey.do -o pngquant -f --ext .png --quality 90-95 "$file"
  fi
  wl-copy --type image/png <"$file"
  hey.do notify-send \
    -a hey.screenshot \
    -i $file \
    "Sent screenshot to ${dest[2]:-clipboard}"
  hey .play-sound blip
  sleep 1  # give time for notify to use image file
}

main $@
