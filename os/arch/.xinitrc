#!/bin/sh

[[ -f $HOME/.Xresources ]] && xrdb ~/.Xresources
[[ -f $HOME/.xprofile ]] && source ~/.xprofile
[[ -f $HOME/.Xmodmap ]] && xmodmap ~/.Xmodmap

exec bspwm
