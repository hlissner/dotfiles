#!/bin/bash

# https://github.com/jamiew/git-friendly
bash < <( curl https://raw.github.com/jamiew/git-friendly/master/install.sh)

# https://rvm.io
curl -L https://get.rvm.io | bash -s stable --ruby

# http://mxcl.github.com/homebrew/
ruby <(curl -fsSkL raw.github.com/mxcl/homebrew/go)

# https://github.com/robbyrussell/oh-my-zsh
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh

# Create links
src=$(cd "$(dirname "$0")"; pwd)

ln -sf $src/zshrc ~/.zshrc
ln -sf $src/zsh ~/.zsh
ln -sf $src/gitignore ~/.gitignore
ln -sf $src/gitconfig ~/.gitconfig
