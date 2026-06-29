#!/usr/bin/env zsh
# Wakeup from sleep.
#
# SYNOPSIS:
#   hey hook onResumeFromSleep
#
# SYNOPSIS:
#   Triggered by Dank Actions plugin when the system wakes from sleep.

dms ipc toast info "Waking up..."
hey .play-sound wakeup
