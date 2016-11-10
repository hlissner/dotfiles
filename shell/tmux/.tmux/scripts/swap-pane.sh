#!/usr/bin/env bash

swap() { tmux swap-pane -s"$1" -t"$2"; }

CONF=~/.tmux/lastpane

target=
case $1 in
    up) target="U" ;;
    down) target="D" ;;
    left) target="L" ;;
    right) target="R" ;;
    master) target="M" ;;
    *) exit 1 ;;
esac

src_pane=$(tmux display-message -p "#P")
tmux select-pane -${target}

dst_pane=$(tmux display-message -p "#P")
tmux select-pane -${src_pane}

if [[ "$target" == "M" ]]; then
    dst_pane=0
fi
swap "$src_pane" "$dst_pane"
tmux select-pane -t"$dst_pane"
