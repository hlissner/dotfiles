#!/bin/bash

src=$(cd "$(dirname "$0")"; pwd)

if [ ! -d $src/install ]; then
    echo
    echo "* Cloning dotfiles repo"
    git clone https://github.com/hlissner/dotfiles.git ~/.dotfiles
    src="~/.dotfiles"
fi

$src/install/osx
$src/install/zsh
$src/install/brew
$src/install/git
$src/install/rvm
$src/install/tmux

echo
echo "Done!"
echo "And if you want to install vim, run:"
echo "   sh <(curl https://raw.github.com/hlissner/mlvim/master/install.sh -L)"
