#!/usr/bin/env bash

_clone() { [ -d "$2" ] || git clone --recursive "$1" "$2"; }

# In case this file was run via curl
_clone https://github.com/hlissner/dotfiles ~/.dotfiles
_clone https://github.com/hlissner/.vim ~/.vim
_clone https://github.com/tarjoilija/zgen ~/.zgen
_clone https://github.com/jimeh/tmuxifier ~/.tmuxifier

if [ "$(name)" == "Darwin" ]; then
    _clone https://github.com/hlissner/.hammerspoon ~/.hammerspoon
fi

shopt -s extglob
for rcfile in "${HOME}"/.dotfiles/!(.*|bin|scripts|*.md|install.sh)
do
    filep="$HOME/."$(basename "$rcfile")

    [ "$1" == "--force" ] && rm -f "$filep"
    [ -e "$filep" ] || ln -vs "$rcfile" "$filep"
done
