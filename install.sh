#!/bin/sh

function do_link {
    if [ ! -h "$2" ]; then
        ln -sf "~/.dotfiles/$1" "$2"
    fi
}

[ ! -d ~/.dotfiles ] && git clone git@github.com:hlissner/dotfiles.git ~/.dotfiles

do_link zsh $HOME/.zsh
do_link zshrc $HOME/.zshrc
do_link zshenv $HOME/.zshenv
do_link tmux.conf $HOME/.tmux.conf
do_link gitignore $HOME/.gitignore
do_link gitconfig $HOME/.gitconfig
do_link bashrc $HOME/.bashrc
do_link ctags $HOME/.ctags
do_link rake $HOME/.rake
