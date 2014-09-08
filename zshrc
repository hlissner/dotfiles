# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source ~/.zsh/preztorc
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Source component rcfiles
source ~/.zsh/config
source ~/.zsh/aliases

# Init extra niceties
command_exists "fasd" && eval "$(fasd --init auto)"
