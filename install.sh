#!/bin/bash

GREEN=$(tput setaf 2)
RS=$(tput sgr0)

src=$(cd "$(dirname "$0")"; pwd)
if [ ! -d $src/install ]; then
    echo -e "$GREEN==> Cloning dotfiles repo$RS"
    git clone https://github.com/hlissner/dotfiles.git ~/.dotfiles | sed "s/^/  /"
    src="~/.dotfiles"
fi

$src/install/osx
$src/install/zsh
$src/install/brew
$src/install/git
$src/install/rvm
$src/install/tmux

echo
echo "${GREEN}Done!$RS"
echo "And if you want to install vim, run:"
echo "   sh <(curl https://raw.github.com/hlissner/mlvim/master/install.sh -L)"
