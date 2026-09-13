#!/usr/bin/env zsh
# Fade the screen to or from black.
#
# SYNOPSIS:
#   fade out [-d MS] [-c COLOR]
#   fade in [-d MS] [-c COLOR]
#   fade kill
#
# DESCRIPTION:
#   Paints a quickshell overlay across every monitor and animates a fade-in/out
#   effect (also hides/shows the cursor). Useful for pre-shutdown or
#   post-startup scripts (like hey's onStartup and onRequestSuspend hooks). Also
#   temporarily binds Escape to kill the fade overlay.
#
#   Its defaults come from modules.hyprland.fade. Turning that module off makes
#   this script do nothing without -d and -c.
#
#   REQUIRES: quickshell, hyprctl, jq
#
# OPTIONS:
#   -d MS
#     Fade for MS milliseconds instead of the module default.
#   -c COLOR
#     Fade to COLOR instead of the module default. Accepts anything QML takes:
#     #rrggbb, a named colour, etc.
#
# ARGUMENTS:
#   1 DIRECTION
#     out   -- Fade to black and hold it there.
#     in    -- Fade back in from black.
#     kill  -- Take the overlay away at once; what Escape runs.

local -a o_duration o_color
zparseopts -E -D -F -- d:=o_duration c:=o_color || exit 1

local dir=$1
if [[ $dir != (in|out|kill) ]]; then
  hey.error "Expected 'out', 'in' or 'kill', got: ${dir:-nothing}"
  exit 2
fi
(( $+commands[quickshell] )) || exit 0

local ms color secs
if [[ $dir != kill ]]; then
  local info=$(hey info hypr fade 2>/dev/null)
  [[ $info == null ]] && info=
  if [[ -z $info ]]; then
    [[ -n $o_duration || -n $o_color ]] \
      || hey.abort "modules.hyprland.fade is disabled; pass -d and/or -c to fade anyway"
    info='{}'
  fi

  # For when neither the module nor the caller have opinions
  ms=${o_duration[2]:-$(jq -r '.duration // 500' <<<$info)}
  color=${o_color[2]:-$(jq -r '.color // "#000000"' <<<$info)}
  [[ $ms == <-> ]] || hey.abort "-d wants milliseconds, got: $ms"
  secs=$(( ms / 1000.0 ))
fi

typeset -g prefix=$(hey path runtime fade)
typeset -g qmlfile=$prefix.qml
typeset -g pidfile=$prefix.pid
mkdir -p ${prefix:h}

# Emit the overlay's quickshell config. Done inline to keep this script
# self-contained, the same way screencast.zsh does its region indicator.
_fade_qml() {
  echo 'import QtQuick'
  echo 'import Quickshell'
  echo 'import Quickshell.Io'
  echo 'import Quickshell.Wayland'
  echo
  echo 'ShellRoot {'
  echo '    id: root'
  echo
  echo '    readonly property int ms: Number(Quickshell.env("HYPR_FADE_MS") || 500)'
  echo '    readonly property color ink: Quickshell.env("HYPR_FADE_COLOR") || "#000000"'
  echo
  echo '    // Starts clear so the surface can map -- and hyprland can run its'
  echo '    // own layer-open fade -- unseen. The script only asks for black once'
  echo '    // the surface is up, so quickshell'"'"'s startup eats none of the fade.'
  echo '    property real target: 0'
  echo
  echo '    IpcHandler {'
  echo '        target: "fade"'
  echo '        function out(): string { root.target = 1; return "out" }'
  echo '        function restore(): string { root.target = 0; return "in" }'
  echo '    }'
  echo
  echo '    Variants {'
  echo '        model: Quickshell.screens'
  echo
  echo '        PanelWindow {'
  echo '            required property var modelData'
  echo
  echo '            screen: modelData'
  echo '            color: "transparent"'
  echo '            focusable: false'
  echo '            mask: Region {}  // an empty region is entirely click-through'
  echo '            exclusionMode: ExclusionMode.Ignore'
  echo '            anchors { left: true; right: true; top: true; bottom: true }'
  echo
  echo '            WlrLayershell.layer: WlrLayer.Overlay'
  echo '            WlrLayershell.namespace: "hypr-fade"'
  echo '            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None'
  echo
  echo '            Rectangle {'
  echo '                anchors.fill: parent'
  echo '                color: root.ink'
  echo '                opacity: root.target'
  echo
  echo '                // A Behavior rather than a value-source animation, so'
  echo '                // opacity keeps its binding and nothing fights it'
  echo '                // halfway through the fade.'
  echo '                Behavior on opacity {'
  echo '                    NumberAnimation {'
  echo '                        duration: root.ms'
  echo '                        easing.type: Easing.InOutQuad'
  echo '                    }'
  echo '                }'
  echo '            }'
  echo '        }'
  echo '    }'
  echo '}'
}

_fade_running() {
  local pid
  [[ -f $pidfile ]] && pid="$(<$pidfile)"
  # In case of a stale pidfile with a recycled pid
  [[ $pid == <-> ]] && [[ -r /proc/$pid/cmdline ]] \
    && [[ "$(tr '\0' ' ' </proc/$pid/cmdline)" == *$qmlfile* ]]
}

_fade_cursor() {
  hyprctl eval "hl.config({ cursor = { invisible = $1 } })" &>/dev/null
}

# Temporarily bind ESC as an emergency abort (only aborts the fade, not whatever
# initiated it).
_fade_bind() {
  hyprctl keyword bind ",escape,exec,hey .fade kill" &>/dev/null
}

_fade_unbind() {
  hyprctl keyword unbind ",escape" &>/dev/null
}

_fade_stop() {
  _fade_unbind
  _fade_running && kill "$(<$pidfile)" 2>/dev/null
  rm -f "$pidfile"
  _fade_cursor false
}

_fade_start() {
  _fade_bind
  _fade_qml >|$qmlfile
  QS_DISABLE_FILE_WATCHER=1 \
    QS_NO_RELOAD_POPUP=1 \
    HYPR_FADE_MS=$ms \
    HYPR_FADE_COLOR=$color \
    quickshell -p $qmlfile &>/dev/null &!
  print -r -- $! >|$pidfile
}

_fade_ipc() {  # FUNCTION
  quickshell ipc --pid "$(<$pidfile)" call fade $1 &>/dev/null
}

# Block until the overlay's surfaces exist. Cold-starting quickshell costs
# ~130ms, so animate nothing before then.
_fade_wait_mapped() {
  local deadline=$(( SECONDS + 2 ))
  while (( SECONDS < deadline )); do
    hyprctl layers 2>/dev/null | grep -q "namespace: hypr-fade" && return 0
    sleep 0.02
  done
  return 1
}

case $dir in
  out)
    if ! _fade_running; then
      _fade_stop  # clear a stale pidfile
      _fade_start
      _fade_wait_mapped || exit 0
    fi
    _fade_ipc out
    sleep $secs  # wait for shutdown/suspend to take us to narnia
    _fade_running && _fade_cursor true  # hide cursor (loud on black)
    ;;
  in)
    _fade_running || { _fade_cursor false; exit 0 }
    _fade_ipc restore
    sleep $secs
    _fade_stop
    ;;
  kill)
    # Emergency kill command
    _fade_stop
    ;;
esac
