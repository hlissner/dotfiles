#!/usr/bin/env zsh
# Record a region of the screen to clipboard.
#
# SYNOPSIS:
#   screencast [webm|mp4|gif] [TARGET] [DELAY]
#
# DESCRIPTION:
#   Prompts the user to select a region, window, or monitor to begin recording
#   with wf-recorder. Produces a webm by default, but can also produce mp4' or
#   gifs. If quickshell is present, a dashed outline will highlight the recorded
#   region until the recording ends.
#
# DEPENDENCIES:
#   wf-recorder, ffmpeg, quickshell*, gifsicle**
#
#   * Optional: needed for the region indicator
#   ** Is auto-installed by cached-nix-shell if needed.
#
# ARGUMENTS:
#   1 FORMAT
#     webm      -- Optimized for short recordings of text or code (the default).
#     mp4       -- Optimized for high-motion content.
#     gif       -- Produce an animated gif.
#   2 TARGET
#     last      -- Reuse the previous selection.
#     region    -- Select an arbitrary region (the default).
#     window    -- Select a window.
#     output    -- Select a monitor.
#   3 DELAY

# Emit the quickshell config for the region indicator. Done inline to keep this
# script self-contained.
_indicator_qml() {
  echo 'import QtQuick'
  echo 'import QtQuick.Shapes'
  echo 'import Quickshell'
  echo 'import Quickshell.Wayland'
  echo
  echo 'ShellRoot {'
  echo '    id: root'
  echo
  echo '    // The region to outline, in global (compositor) coordinates.'
  echo '    readonly property real regionX: Number(Quickshell.env("SCREENCAST_X") || 0)'
  echo '    readonly property real regionY: Number(Quickshell.env("SCREENCAST_Y") || 0)'
  echo '    readonly property real regionW: Number(Quickshell.env("SCREENCAST_W") || 0)'
  echo '    readonly property real regionH: Number(Quickshell.env("SCREENCAST_H") || 0)'
  echo
  echo '    readonly property real thickness: 2'
  echo "    readonly property color ink: \"${SCREENCAST_OUTLINE_COLOR:-#ff4d4d}\""
  echo
  echo '    // Strokes are centered on its path, so the path must sit half a stroke out.'
  echo '    readonly property real offset: 2 + thickness / 2'
  echo
  echo '    Variants {'
  echo '        model: Quickshell.screens'
  echo
  echo '        PanelWindow {'
  echo '            id: win'
  echo '            required property var modelData'
  echo
  echo '            readonly property real boxLeft: root.regionX - root.offset - modelData.x'
  echo '            readonly property real boxTop: root.regionY - root.offset - modelData.y'
  echo '            readonly property real boxRight: boxLeft + root.regionW + root.offset * 2'
  echo '            readonly property real boxBottom: boxTop + root.regionH + root.offset * 2'
  echo
  echo '            screen: modelData'
  echo '            // Do not map a surface on monitors the outline cannot reach.'
  echo '            visible: root.regionW > 0 && root.regionH > 0'
  echo '                     && boxRight >= 0 && boxBottom >= 0'
  echo '                     && boxLeft <= modelData.width && boxTop <= modelData.height'
  echo
  echo '            color: "transparent"'
  echo '            focusable: false'
  echo '            mask: Region {}  // an empty region is entirely click-through'
  echo '            exclusionMode: ExclusionMode.Ignore'
  echo '            anchors { left: true; right: true; top: true; bottom: true }'
  echo
  echo '            WlrLayershell.layer: WlrLayer.Overlay'
  echo '            WlrLayershell.namespace: "screencast-region"'
  echo '            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None'
  echo
  echo '            Shape {'
  echo '                anchors.fill: parent'
  echo '                preferredRendererType: Shape.GeometryRenderer  // dashes need it'
  echo
  echo '                ShapePath {'
  echo '                    fillColor: "transparent"'
  echo '                    strokeColor: root.ink'
  echo '                    strokeWidth: root.thickness'
  echo '                    strokeStyle: ShapePath.DashLine'
  echo '                    dashPattern: [4, 3]             // in units of strokeWidth'
  echo '                    capStyle: ShapePath.FlatCap     // SquareCap would overhang'
  echo '                    joinStyle: ShapePath.MiterJoin  // miters point outward only'
  echo
  echo '                    startX: win.boxLeft'
  echo '                    startY: win.boxTop'
  echo '                    PathLine { x: win.boxRight; y: win.boxTop }'
  echo '                    PathLine { x: win.boxRight; y: win.boxBottom }'
  echo '                    PathLine { x: win.boxLeft;  y: win.boxBottom }'
  echo '                    PathLine { x: win.boxLeft;  y: win.boxTop }'
  echo
  echo '                    NumberAnimation on dashOffset {'
  echo '                        from: 7'
  echo '                        to: 0'
  echo '                        duration: 600'
  echo '                        loops: Animation.Infinite'
  echo '                    }'
  echo '                }'
  echo '            }'
  echo '        }'
  echo '    }'
  echo '}'
}

_indicator() {  # X Y W H
  command -v quickshell >/dev/null || return 0
  _indicator_qml >|$qmlfile
  _indicator_stop  # in case of a SIGKILLed run
  QS_DISABLE_FILE_WATCHER=1 \
    QS_NO_RELOAD_POPUP=1 \
    SCREENCAST_X=$1 \
    SCREENCAST_Y=$2 \
    SCREENCAST_W=$3 \
    SCREENCAST_H=$4 \
    quickshell -p $qmlfile &>/dev/null &!
  print -r -- $! >|$pidfile
}

_indicator_stop() {
  local pid
  [[ -f $pidfile ]] && pid="$(<$pidfile)"
  # In case of a stale pidfile with a recycled pid
  if [[ $pid == <-> ]] && [[ "$(tr '\0' ' ' </proc/$pid/cmdline 2>/dev/null)" == *$qmlfile* ]]; then
    kill $pid 2>/dev/null
  fi
  rm -f "$pidfile"
  return 0
}

_cleanup() {
  _indicator_stop
  rm -f "$livefile" "$qmlfile"
  return 0
}

main() {
  hey.requires wf-recorder ffmpeg

  local file
  local -a opts=( --audio-backend pipewire )
  if [[ -f "$livefile" ]]; then
    pkill -SIGINT wf-recorder
    _indicator_stop  # instant feedback; don't wait on the muxer
    rm -f "$livefile"
    return
  fi
  case "${1:-webm}" in
    webm)
      file="$prefix.webm"
      # Optimized for short (sub-30s) recordings of text/code. Use mp4 for
      # gaming-quality recordings.
      opts+=( \
        -c libvpx-vp9 -x yuv444p -r 30 \
        -p crf=24 -p cpu-used=0 -p deadline=good \
        -p row-mt=1 -p tile-columns=2 -p b=0 -p g=240 \
      )
      ;;
    mp4)
      file="$prefix.mp4"
      # Optimized for high-motion (sub-30s) recordings of high-motion content,
      # like games or video.
      opts+=( \
        --audio -c libx264 -r 60 -B 60 -b 5 \
        -p preset=slow -p tune=animation -p crf=18 \
        -p g=300 -p keyint_min=60 -p aq-mode=3 \
        -p profile=high -p level=4.2 \
      )
      ;;
    gif)
      file="$prefix.gif"
      # Not optimized at all. There really is little reason to use gif over
      # webm, but I keep it here for posterity. Ideally, it should be encoded to
      # some other raw format and post-processed to gif with ffmpeg, but I can't
      # be assed to do that here, since I never use this.
      opts+=( --codec gif )
      ;;
    *) hey.abort "Unknown format: $1" ;;
  esac
  rm -f "$file"
  touch "$livefile"
  trap _cleanup EXIT SIGINT SIGTERM
  local geom="$(hey .slurp ${2:-region})"
  [[ -z "$geom" ]] && exit 1
  # slurp prints "X,Y WxH"; validating it is also how we take it apart.
  [[ "$geom" =~ '^(-?[0-9]+),(-?[0-9]+) ([0-9]+)x([0-9]+)$' ]] \
    || hey.abort "Unrecognized geometry: $geom"

  # Up before the countdown, so qt is done warming up by frame one.
  _indicator $match[1] $match[2] $match[3] $match[4]

  local delay="$3"
  if [[ -n "$delay" ]] && (( delay > 0 )); then
    for i in {$delay..1}; do
      hey .play-sound blip &
      hey.toast -c countdown warn "Recording starting in... $i"
      sleep 1
    done
  fi
  # The bar widget (config/noctalia/plugins/screencast) counts up from this.
  print -r -- $EPOCHSECONDS >| $livefile
  wf-recorder -g "$geom" ${opts[@]} --file="$file"
  local rc=$?
  _indicator_stop  # dies with the recording, not with gifsicle
  if (( rc == 0 )); then
    sleep 0.1
    if [[ $1 == gif ]]; then
      hey.toast warn "Optimizing gif. This may take a while..."
      hey.do -! gifsicle --optimize=3 "$file"
    fi
    echo "file://$file" | wl-copy -t text/uri-list
    hey .play-sound success &
    hey.toast info "Recording complete. Copied to clipboard!"
  fi
}

zmodload zsh/datetime  # EPOCHSECONDS

typeset -g prefix=$(hey path runtime screencast)
typeset -g livefile=$prefix.live
typeset -g qmlfile=$prefix.qml
typeset -g pidfile=$prefix.pid
main $@
