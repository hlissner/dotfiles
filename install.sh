#!/bin/sh

function do_link {
    if [ ! -h "$2" ]; then
        ln -sf "~/.dotfiles/$1" "$2"
    fi
}

[ ! -d ~/.dotfiles ] && git clone git@github.com:hlissner/dotfiles.git ~/.dotfiles

do_link zsh ~/.zsh
do_link zshrc ~/.zshrc
do_link zshenv ~/.zshenv
do_link tmux.conf ~/.tmux.conf
do_link gitignore ~/.gitignore
do_link gitconfig ~/.gitconfig
do_link bashrc ~/.bashrc
do_link ctags ~/.ctags
do_link rake ~/.rake
