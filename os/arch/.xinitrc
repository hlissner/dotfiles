#!/bin/sh

[ -f ~/.Xresources ] && xrdb ~/.Xresources
[ -f ~/.xprofile ] && source ~/.xprofile
exec ssh-agent bspwm
