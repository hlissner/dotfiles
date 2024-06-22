#!/usr/bin/env dash
# Open a rofi-based file-browser.
#
# SYNOPSIS:
#   TODO

rofi \
  -modi file-browser-extended \
  -show file-browser-extended \
  -file-browser-path-sep "/" \
  -theme filemenu.rasi \
  $@
