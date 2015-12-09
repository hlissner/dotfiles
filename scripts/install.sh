#!/bin/bash

# In case this file was run via curl
[ ! -d ~/.dotfiles ] && git clone --recursive https://github.com/hlissner/dotfiles ~/.dotfiles
[ ! -d ~/.vim ] && git clone --recursive https://github.com/hlissner/vim ~/.vim

~/.vim/install.sh

shopt -s extglob
for rcfile in "$HOME"/.dotfiles/!(bin|scripts|README.md|Gemfile*); do
    filep="$HOME/."$(basename "$rcfile")

    [ "$1" == "--force" ] && rm -f "$filep"
    [ -e "$filep" ] && continue
    ln -vsF "$rcfile" $filep
done
