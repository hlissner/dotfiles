#!/bin/sh

[ -f ~/.xprofile ] && source ~/.xprofile
exec ssh-agent bspwm
