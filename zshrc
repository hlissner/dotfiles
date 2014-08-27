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

# If OSX...
if command_exists "brew"; then
    export RBENV_ROOT=/usr/local/opt/rbenv
    export PYENV_ROOT=/usr/local/opt/pyenv
fi

# Init extra niceties
command_exists "fasd" && eval "$(fasd --init auto)"
command_exists "rbenv" && eval "$(rbenv init - --no-rehash)"
command_exists "pyenv" && eval "$(pyenv init -)"
