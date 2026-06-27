#!/usr/bin/env zsh
# Record a region of the screen to clipboard.
#
# SYNOPSIS:
#   screencast [webm|mp4|gif] [X,Y WxH]
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

main() {
  hey.requires wf-recorder ffmpeg

  local prefix=$(hey path runtime screencast)
  local livefile=$prefix.live
  local thumbfile=$prefix.thumb.png
  local file
  local -a opts=( --audio-backend pipewire )
  if [[ -f "$livefile" ]]; then
    pkill -SIGINT wf-recorder
    rm -f "$thumbfile" "$livefile"
    return
  fi
  case "${1:-webm}" in
    webm)
      file="$prefix.webm"
      opts+=( --audio -c libvpx -C libvorbis -p crf=20 -p speed=1 -p lag-in-frames=15 -p cpu-used 0 )
      ;;
    mp4)
      file="$prefix.mp4"
      opts+=( --audio -c libx264 -p preset=slow -p crf=21 )
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
  trap "rm -f '$thumbfile' '$livefile'" EXIT SIGINT SIGTERM
  local geom="$(hey .slurp ${2:-region})"
  [[ -z "$geom" ]] && exit 1
  local id=$(notify-send -p -a "" "Recording starting in 3...")
  sleep 1
  hey .play-sound blip
  notify-send -r "$id" -a "" "<b>Recording starting in 2...</b>"
  sleep 1
  hey .play-sound blip
  notify-send -r "$id" -a "" "<i><b>Recording starting in 1...</b></i>"
  sleep 1
  notify-send -r "$id" -a "" "Recording started..."
  if wf-recorder -g "$geom" ${opts[@]} --file="$file"; then
    sleep 0.1
    hey.do ffmpeg -y -i "$file" -frames:v 1 "$thumbfile"
    if [[ $1 == gif ]]; then
      notify-send -a "screencast.zsh" -u low -i "$thumbfile" "Optimizing gif" "This may take a while..."
      hey.do -! gifsicle --optimize=3 "$file"
    fi
    echo "file://$file" | wl-copy -t text/uri-list
    notify-send -a "screencast.zsh" -i "$thumbfile" "Ended recording" "Sent uri to clipboard"
  fi
}

main $@
