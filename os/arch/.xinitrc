#!/bin/sh

[[ -f $HOME/.Xresources ]] && xrdb ~/.Xresources
[[ -f $HOME/.xprofile ]] && source ~/.xprofile

exec bspwm
