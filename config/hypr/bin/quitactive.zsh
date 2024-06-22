#!/usr/bin/env zsh
# Kill the selected window.
#
# SYNOPSIS:
#   quitactive
#
# DESCRIPTION:
#   Unlike the closewindow (or killactive) dispatchers, this actually tries to
#   elegantly (but immediately) kill the target application window.

local pid=$(hyprctl activewindow -j | jq .pid)
[[ $pid ]] && kill -SIGTERM "$pid"
