#!/bin/zsh

function command_exists {
    command -v "$1" &> /dev/null
}

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source ~/.zsh/preztorc
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Source component rcfiles
source ~/.zsh/aliases
source ~/.zsh/config

# Init extra niceties
command_exists "fasd" && eval "$(fasd --init auto)"
command_exists "rbenv" && eval "$(rbenv init - --no-rehash)"
if command_exists "pyenv"; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
if command_exists "go"; then
    export GOPATH="$HOME/Dropbox/Projects/dev/go"
    export PATH="$GOPATH/bin:$PATH"
fi
