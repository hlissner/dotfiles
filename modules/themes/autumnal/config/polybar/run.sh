#!/usr/bin/env bash

group_a=( clock date date_day )
group_b=( memory cpu fs-root fs-home )

msg() {
  action="module_$1"
  shift
  for mod in "$@"; do
    polybar-msg action "$mod" "$action"
  done
}

if [[ "$1" == "switch" ]]; then
case "$2" in
  0)
    msg hide "${group_b[@]}"
    msg show "${group_a[@]}"
    ;;
  1)
    msg show "${group_b[@]}"
    msg hide "${group_a[@]}"
    ;;
esac
else
  pkill -u $UID -x polybar
  while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

  echo 'Launching Polybar...'
  {
    sleep 1
    polybardir="$XDG_DATA_HOME/polybar"
    mkdir -p "$polybardir"
    polybar main >"$polybardir/main.log" 2>&1 &
  } &
fi
