#!/usr/bin/env zsh
# Executed at shutdown
#
# SYNOPSIS:
#   hey hook onShutdown
#
# SYNOPSIS:
#   Triggered by NixOS while shutting down..

dms ipc toast info "Powering off..."
hey .play-sound shutdown
