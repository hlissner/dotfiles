#!/bin/zsh

# In case this file was run via curl
[ ! -d ~/.dotfiles ] && git clone https://github.com/hlissner/dotfiles ~/.dotfiles
[ ! -d ~/.zprezto ] && git clone --recursive https://github.com/hlissner/prezto ~/.zprezto

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.dotfiles/^(bin|README.md|Gemfile|install.sh)(N); do
    filep="${ZDOTDIR:-$HOME}/.${rcfile:t}"

    if [ -e "$filep" ]; then
        echo "~/.${rcfile:t} already existed. Skipping..."
        continue
    else
        echo "Linking ${rcfile:t} to ~/.${rcfile:t}"
    fi

    ln -s "$rcfile" $filep
done
