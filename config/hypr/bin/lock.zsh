#!/usr/bin/env zsh
# Launch hyprlock.
#
# SYNOPSIS:
#  lock [OPTIONS]
#
# DESCRIPTION:
#   A wrapper around hyprlock that is able to modify its settings on a per-call
#   basis, for specialized use-cases.
#
# OPTIONS:
#   --bg IMAGE
#   --bg-color COLOR
#   --no-blur
#   --brightness FLOAT
#   --no-fade-{in,out}

if (( $# > 0 )); then
  local tmpfile=$(hey path runtime hyprlock.tmp.conf)
  trap "rm -f '$tmpfile'" EXIT

  zparseopts -D -- -no-fade-in=fadein \
                   -no-fade-out=fadeout \
                   -grace:=grace \
                   -bg:=bg \
                   -bg-color:=bgcolor \
                   -no-blur=blur \
                   -brightness:=brightness

  local monitor=
  cat <<EOF >"$tmpfile"
    source = ~/.config/hypr/hyprlock.conf
    general {
      ${fadein:+no_fade_in = true}
      ${fadeout:+no_fade_out = true}
      ${grace:+grace = ${grace[2]}}
    }
EOF

  # hyprlock breaks trying to take screenshots on nvidia machines, so I gotta
  # shim support in myself.
  #
  # @see hyprwm/hyprlock#59
  if [[ ${bg[2]} == screenshot ]]; then
    local -a files=( -l 0 )
    for m in $(hyprctl monitors -j | jq -r '.[].name'); do
      files+="/tmp/hyprlock.$m.png"
      echo "Taking ${files[-1]}"
      hey.do -! grim -l 0 -o "$m" "${files[-1]}" &
      cat <<EOF >>"$tmpfile"
        background {
          monitor = $m
          path = ${files[-1]}
          ${bgcolor:+color = ${bgcolor[2]}}
          ${blur:+blur_passes = 0}
          ${brightness:+brightness = ${brightness[2]}}
        }
EOF
    done
    echo waiting
    while pidof -s grim >/dev/null; do sleep 0.25; done
    trap "rm -f ${files[*]}" EXIT
  else
    cat <<EOF >>"$tmpfile"
      background {
        monitor =
        ${bg:+path = ${bg[2]}}
        ${bgcolor:+color = ${bgcolor[2]}}
        ${blur:+blur_passes = 0}
        ${brightness:+brightness = ${brightness[2]}}
      }
EOF
  fi

  hey.log -3 "$tmpfile"

  exec hyprlock -c "$tmpfile" $@
fi

exec hyprlock $@
