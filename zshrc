#!/bin/zsh

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source ~/.zsh/preztorc
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Source component rcfiles
source ~/.zsh/functions
source ~/.zsh/aliases
source ~/.zsh/config

# Init rbenv & pyenv
command_exists "rbenv" && eval "$(rbenv init -)"
command_exists "pyenv" && eval "$(pyenv init -)"
command_exists "fasd" && eval "$(fasd --init auto)"
