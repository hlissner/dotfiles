#!/bin/bash

# In case this file was run via curl
[ ! -d ~/.dotfiles ] && git clone https://github.com/hlissner/dotfiles ~/.dotfiles
[ ! -d ~/.zprezto ] && git clone --recursive https://github.com/hlissner/prezto ~/.zprezto

shopt -s extglob
for rcfile in "$HOME"/.dotfiles/!(bin|README.md|Gemfile|install.sh); do
    filep="$HOME/."$(basename "$rcfile")

    [ -e "$filep" ] && continue
    ln -vs "$rcfile" $filep
done
