#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload @niri
#
# DESCRIPTION:
#   niri polls its config and every include every 500ms on its own, so this
#   only makes a reload immediate -- and loud, since a broken config gets its
#   error reported back here rather than in a notification I may have missed.

hey.do niri msg action load-config-file
