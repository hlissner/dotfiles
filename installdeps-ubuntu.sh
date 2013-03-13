#!/bin/bash

sudo apt-get update
sudo apt-get install zsh git curl

# Install oh-my-zsh
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh

# Change shell
chsh -s /bin/zsh

# Create links
src=$(cd "$(dirname "$0")"; pwd)

ln -sf $src/zshrc ~/.zshrc
ln -sf $src/zsh ~/.zsh
ln -sf $src/gitignore ~/.gitignore
ln -sf $src/gitconfig ~/.gitconfig
