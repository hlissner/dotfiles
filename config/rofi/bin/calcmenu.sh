#!/usr/bin/env dash
# Launch a rofi-powered calculator.
#
# SYNOPSIS:
#   calcmenu

rofi \
  -show calc \
  -modi calc \
  -theme calcmenu \
  $@
