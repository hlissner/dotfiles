#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload @noctalia
#
# DESCRIPTION:
#   Reloads Noctalia's config and regenerates theme templates.

echo "noctalia: reloading config"
hey.do noctalia msg config-reload

echo "noctalia: re-rendering templates"
hey.do noctalia msg templates-apply
