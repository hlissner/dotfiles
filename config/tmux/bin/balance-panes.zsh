#!/usr/bin/env zsh
# Even out every split in the current window.
#
# SYNOPSIS:
#   balance-panes
#
# DESCRIPTION:
#   Resizes all panes in the frame to be equal in width/height. Takes
#   inspiration from `balance-windows` in Emacs.

local pane
for pane in ${(f)"$(tmux list-panes -F '#{pane_id}')"}; do
  hey.do tmux select-layout -E -t "$pane"
done
