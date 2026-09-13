#!/usr/bin/env zsh
# Executed at shutdown
#
# SYNOPSIS:
#   hey hook onShutdown
#
# SYNOPSIS:
#   Triggered by NixOS while shutting down..

dms ipc toast warn "Shutting down..."

# Fade while the sound plays; powermenu.zsh waits on this hook before it calls
# systemctl, so the screen is already black when the session goes.
hey .fade out &
hey .play-sound -w shutdown
wait
