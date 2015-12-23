#!/usr/bin/env bash

_clone() { [[ -d "$2" ]] || git clone --recursve "$1" "$2"; }

# In case this file was run via curl
_clone https://github.com/hlissner/dotfiles ~/.dotfiles

shopt -s extglob
for rcfile in "${HOME}"/.dotfiles/!(.*|bin|scripts|*.md|install.sh)
do
    filep="$HOME/."$(basename "$rcfile")

    [ "$1" == "--force" ] && rm -f "$filep"
    [ -e "$filep" ] || ln -vs "$rcfile" "$filep"
done

# Install fzf and fasd
case $OSTYPE in
    darwin*)
        brew install fzf fasd
        ;;
    linux*)
        _clone https://github.com/junegunn/fzf ~/.fzf
        _clone https://github.com/clvv/fasd ~/fasd && \
            cd ~/fasd && make install && rm -rf ~/fasd
        ;;
esac
