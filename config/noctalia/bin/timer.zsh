#!/usr/bin/env zsh
# Start a countdown on Noctalia's timer widget.
#
# SYNOPSIS:
#   hey @noctalia timer [DURATION...]
#   hey @noctalia timer -p
#
# DESCRIPTION:
#   DURATION is a human readable duration: `25m`, `2h 4m`, `7m 5s`, `90s`. Order
#   doesn't matter. Defaults to minutes if no unit is specified. A `0` resets
#   any running timer.
#
# OPTIONS:
#   -p, --prompt
#     Prompt for DURATION through rofi rather than reading it off the command
#     line.
#
# ARGUMENTS:
#   ** DURATION

local -a o_prompt
zparseopts -E -D -F -- p=o_prompt -prompt=o_prompt || exit 1

hey.requires noctalia

# Prints DURATION as seconds, or nothing if any of it is unreadable
timer.seconds() {
  local spec=${(L)${(j::)@}//[[:space:]]/} total=0 parsed=
  while [[ $spec =~ '^([0-9]+)([hms]?)' ]]; do
    parsed=1
    case ${match[2]:-m} in
      h) (( total += match[1] * 3600 )) ;;
      m) (( total += match[1] * 60 )) ;;
      s) (( total += match[1] )) ;;
    esac
    spec=${spec#$MATCH}
  done
  [[ -z $spec && $parsed ]] && print -r -- $total
}

if (( $#o_prompt )); then
  hey.requires rofi
  local answer
  answer=$(hey @rofi read -I alarm-symbolic -P 'e.g. 14m 5s') || exit 0
  [[ -n ${answer//[[:space:]]/} ]] || exit 0
  set -- "$answer"
elif (( $# == 0 )); then
  # panel-open, not panel-toggle: asking twice should leave it open.
  exec noctalia msg panel-open hey/timer:panel
fi

local secs
secs=$(timer.seconds "$@") ||
  hey.abort "Can't read a duration out of: $*"

local -a event
(( secs == 0 )) && event=( reset ) || event=( start $secs )

local out
out=$(hey.do noctalia msg plugin hey/timer:timer all $event)
[[ $out == error:* ]] && hey.abort "Noctalia wouldn't take it: ${out#error: }"

if (( secs == 0 )); then
  hey.echo -c green "Timer cleared."
else
  hey.echo -c green "Timer set for $(printf '%d:%02d:%02d' \
    $((secs / 3600)) $((secs % 3600 / 60)) $((secs % 60)))."
fi
