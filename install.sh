#!/bin/bash

# In case this file was run via curl
[ ! -d ~/.dotfiles ] && git clone https://github.com/hlissner/dotfiles ~/.dotfiles
[ ! -d ~/.zprezto ] && git clone --recursive https://github.com/hlissner/prezto ~/.zprezto
if [ ! -d ~/.dotfiles/vim/bundle/neobundle.vim ]; then
    mkdir -p ~/.dotfiles/vim/bundle
    git clone --recursive https://github.com/Shougo/neobundle.vim ~/.dotfiles/vim/bundle/neobundle.vim
fi

shopt -s extglob
for rcfile in "$HOME"/.dotfiles/!(bin|README.md|Gemfile*|install.sh); do
    filep="$HOME/."$(basename "$rcfile")

    [ "$1" == "--force" ] && rm -f "$filep"
    [ -e "$filep" ] && continue
    ln -vsF "$rcfile" $filep
done
