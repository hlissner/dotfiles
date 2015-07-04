#!/bin/bash

# In case this file was run via curl
[ ! -d ~/.dotfiles ] && git clone https://github.com/hlissner/dotfiles ~/.dotfiles

shopt -s extglob
for rcfile in "$HOME"/.dotfiles/!(bin|README.md|Gemfile*|install.sh); do
    filep="$HOME/."$(basename "$rcfile")

    [ "$1" == "--force" ] && rm -f "$filep"
    [ -e "$filep" ] && continue
    ln -vsF "$rcfile" $filep
done
