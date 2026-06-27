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
  local file
  local -a opts=( --audio-backend pipewire )
  if [[ -f "$livefile" ]]; then
    pkill -SIGINT wf-recorder
    rm -f "$livefile"
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
  trap "rm -f '$livefile'" EXIT SIGINT SIGTERM
  local geom="$(hey .slurp ${2:-region})"
  [[ -z "$geom" ]] && exit 1

  for i in {3..1}; do
    hey .play-sound blip &
    dms ipc toast dismiss countdown  # debounce
    dms ipc toast warnWith "Recording starting in... $i" "" "" countdown
    sleep 1
  done
  dms ipc toast dismiss countdown
  if wf-recorder -g "$geom" ${opts[@]} --file="$file"; then
    sleep 0.1
    if [[ $1 == gif ]]; then
      dms ipc toast warn "Optimizing gif. This may take a while..."
      hey.do -! gifsicle --optimize=3 "$file"
    fi
    echo "file://$file" | wl-copy -t text/uri-list
    dms ipc toast info "Recording complete. Copied to clipboard!"
  fi
}

main $@
