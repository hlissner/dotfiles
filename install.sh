#!/bin/sh

function do_link {
    if [ ! -h "$HOME/.$1" ]; then
        echo "ln -sf '$HOME/.dotfiles/$1' '$HOME/.$1'"
        ln -sf "$HOME/.dotfiles/$1" "$HOME/.$1"
    fi
}

[ ! -d ~/.dotfiles ] && git clone https://github.com/hlissner/dotfiles ~/.dotfiles

do_link zsh
do_link zshrc
do_link zshenv
do_link tmux.conf
do_link gitignore
do_link gitconfig
do_link bashrc
do_link ctags
do_link rake
