#!/bin/zsh

# In case this file was run via curl
[ ! -d ~/.dotfiles ] && git clone https://github.com/hlissner/dotfiles ~/.dotfiles

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.dotfiles/^(README.md|Gemfile|install.sh)(.N); do
    filep="${ZDOTDIR:-$HOME}/.${rcfile:t}"

    [ -h $filep ] || ln -s "$rcfile" $filep
done
