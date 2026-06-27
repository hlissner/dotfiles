#!/usr/bin/env zsh
# When matugen completes generating from templates.
#
# SYNOPSIS:
#   hey hook onMatugenCompleteda <mode>:<result>
#   hey hook onMatugenCompleteda dark:success
#   hey hook onMatugenCompleteda light:no-changes
#
# SYNOPSIS:
#   Triggered by Dank Actions plugin when Matugen is finished generating its
#   files.

dms ipc toast info "Matugen: completed generating files"
