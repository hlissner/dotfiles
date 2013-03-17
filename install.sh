#!/bin/bash

src=$(cd "$(dirname "$0")"; pwd)

$src/install/osx
$src/install/zsh
$src/install/brew
$src/install/git
$src/install/rvm

echo "\nDone!"
echo "\nAnd if you want to install vim, run:"
echo "\n   sh <(curl https://raw.github.com/hlissner/mlvim/master/install.sh -L)"
