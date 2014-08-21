#!/bin/zsh

# Prevent any of this initialization in non-interactive (or emacs)
# shell commands. It slows them down.
[[ $TERM == "dumb" ]] && return

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

# Init rbenv & pyenv
command_exists "rbenv" && eval "$(rbenv init -)"
command_exists "pyenv" && eval "$(pyenv init -)"
command_exists "fasd" && eval "$(fasd --init auto)"
