#!/usr/bin/env zsh
# Push colors.ini's palette into every running foot window.
#
# SYNOPSIS:
#   hey @foot reload-colors [FILE]
#
# DESCRIPTION:
#   Tosses OSC sequences at zsh shells to get Foot terminals to reload their
#   colors (as best they can, at least). Until I find an alternative terminal
#   with foot's light footprint, but live reload, this is what I'm stuck with.
#   Upstream has decided not to implement it (see
#   https://codeberg.org/dnkl/foot/issues/708).

local file=${1:-${XDG_CONFIG_HOME:-$HOME/.config}/foot/colors.ini}
[[ -r $file ]] || { print -u2 "reload-colors: no $file"; exit 1 }

local seq= bg= alpha=1.0 line key val
for line in ${(f)"$(<$file)"}; do
  [[ $line == [\#\[]* || $line != *=* ]] && continue
  key=${line%%=*}; val=${line#*=}
  case $key in
    foreground)           seq+=$'\e]10;#'$val$'\a' ;;
    background)           bg=$val ;;
    alpha)                alpha=$val ;;
    regular<0-7>)         seq+=$'\e]4;'${key#regular}';#'$val$'\a' ;;
    bright<0-7>)          seq+=$'\e]4;'$(( ${key#bright} + 8 ))';#'$val$'\a' ;;
    selection-foreground) seq+=$'\e]19;#'$val$'\a' ;;
    selection-background) seq+=$'\e]17;#'$val$'\a' ;;
    # foot's cursor= is "TEXT CURSOR"; only the cursor has an OSC.
    cursor)               seq+=$'\e]12;#'${val##* }$'\a' ;;
  esac
done
# A plain #RRGGBB over OSC 11 makes foot opaque again, so the background goes
# out as rgba with alpha= (foot's URxvt-style extension, see foot-ctlseqs(7)).
if [[ -n $bg ]]; then
  local a=$(printf '%02x' $(printf '%.0f' $(( alpha * 255 ))))
  seq+=$'\e]11;rgba:'${bg[1,2]}/${bg[3,4]}/${bg[5,6]}/$a$'\a'
fi
[[ -n $seq ]] || { print -u2 "reload-colors: no colors in $file"; exit 1 }

# Many zshs share one pty (subshells, suspended jobs); resolve fd 0 and write to
# each device once. Anything that isn't a pty is some script's stdin.
local -U ptys=()
local pid pty
for pid in $(pgrep -u $UID -x zsh); do
  pty=$(readlink /proc/$pid/fd/0 2>/dev/null) || continue
  [[ $pty == /dev/pts/* ]] && ptys+=$pty
done
for pty in $ptys; do
  print -rn -- $seq > $pty 2>/dev/null || true
done
