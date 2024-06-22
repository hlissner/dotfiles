#!/usr/bin/env zsh
# Record a region of the screen to clipboard.
#
# SYNOPSIS:
#   screen-record [webm|mp4|gif] [X,Y WxH]
#
# DESCRIPTION:
#   Prompts the user to select a region, window, or monitor to begin recording
#   with wf-recorder. Produces a webm by default, but can also produce mp4' or
#   gifs
#
# DEPENDENCIES:
#   wf-recorder, ffmpeg, gifsicle*
#
#   * Is auto-installed with cached-nix-shell when needed.

.notify() {
  hey.do notify-send \
    -a hey.screencast \
    -h string:x-canonical-private-synchronous:osd \
    -h string:category:preview \
    $@
}

main() {
  hey.requires wf-recorder ffmpeg

  local prefix=$(hey path runtime screencast)
  local livefile=$prefix.live
  local thumbfile=$prefix.thumb.png
  local file
  local -a opts=()
  if [[ -f "$livefile" ]]; then
    pkill -SIGINT wf-recorder
    return
  fi
  case "${1:-webm}" in
    webm)
      file="$prefix.webm"
      opts+=( --audio -x yuv420p -c libvpx -C libvorbis )
      ;;
    mp4)
      file="$prefix.mp4"
      opts+=( --audio -x yuv420p )
      wf-recorder -g "$1" --audio --file="$file" &
      ;;
    gif)
      file="$prefix.gif"
      opts+=( --codec gif )
      ;;
    *) hey.abort "Unknown format: $1" ;;
  esac
  rm -f "$file"
  touch "$livefile"
  trap "rm -f '$thumbfile' '$livefile'" EXIT
  hey .osd toggle --on -P "" "Recording started"
  if wf-recorder -g "$(hey .slurp ${2:-region})" ${opts[@]} --file="$file"; then
    sleep 0.1
    hey .osd toggle --off "" "Recording ended"
    hey.do ffmpeg -y -i "$file" -frames:v 1 "$thumbfile"
    if [[ $1 == gif ]]; then
      .notify -i "$thumbfile" -u low "Optimizing gif" "This may take a while..."
      hey.do -! gifsicle --optimize=3 "$file"
    fi
    echo "file://$file" | wl-copy -t text/uri-list
    .notify -i "$thumbfile" "Ended recording" "Sent uri to clipboard"
  fi
}

main $@
