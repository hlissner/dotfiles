#!/usr/bin/env dash
# Retrieve the { id:, name: } of the (truly) active workspace.
#
# SYNOPSIS:
#   get-activeworkspace [JQ_ARGS...]
#
# DESCRIPTION.
#   Retrieve the { id:, name: } of the (truly) active workspace (does not ignore
#   special workspaces like `hyprctl activeworkspace` does).
#
#   Any arguments are passed to jq.

hyprctl monitors -j \
    | jq -r ".[] | select(.focused)
                 | if .specialWorkspace.id != 0
                   then .specialWorkspace
                   else .activeWorkspace end | ${@:-.}"
