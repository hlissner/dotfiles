#!/usr/bin/env zsh
# reload
#
# TODO

bspc wm -r
. $XDG_CONFIG_HOME/bspwm/bspwmrc

gpgconf --kill gpg-agent
