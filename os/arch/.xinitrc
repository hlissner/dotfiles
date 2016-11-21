#!/bin/sh

xrdb ~/.Xresources
[ -f ~/.xprofile ] && source ~/.xprofile
exec ssh-agent bspwm
