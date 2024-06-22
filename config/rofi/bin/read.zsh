#!/usr/bin/env zsh
# Read input using Rofi.

zparseopts -E -D -F -- P:=placeholder I:=icon -password=secret || exit 1
hey.do rofi \
  -dmenu -lines 1 \
  -theme-str 'mainbox{children:[inputbar,message];}' \
  ${icon[2]:+-theme-str "icon{filename:\"${icon[2]}\";}"} \
  ${placeholder[2]:+-theme-str "entry{placeholder:\"${placeholder:1}\";}"} \
  ${secret:+-password}
