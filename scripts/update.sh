#!/bin/zsh

set -e

brew update && brew upgrade --all
cd "$HOME/.emacs.d" && make update

local i
if [ -d ~/.rbenv ]; then
    cd "$HOME/.rbenv" && git pull
    for i in "$HOME"/.rbenv/plugins/*; do
        cd "$i" && git pull
    done
fi

if [ -d ~/.pyenv ]; then
    cd "$HOME/.pyenv" && git pull
    for i in "$HOME"/.pyenv/plugins/*; do
        cd "$i" && git pull
    done
fi

if [ -d ~/.zsh/zgen ]; then
    source ~/.zsh/zgen/zgen.zsh
    zgen selfupdate
    zgen update
fi
