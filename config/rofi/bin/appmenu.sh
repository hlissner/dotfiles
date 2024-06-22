#!/usr/bin/env dash
# Launch an application with Rofi.
#
# SYNOPSIS:
#   appmenu

rofi \
  -show drun \
  -modi drun,run \
  -theme appmenu.rasi \
  $@
