# Init ZSH
ZSH=$HOME/.oh-my-zsh
plugins=(laravel ruby python brew)
source $ZSH/oh-my-zsh.sh

# Source component rcfiles
. ~/.zsh/paths
. ~/.zsh/aliases
. ~/.zsh/completion
. ~/.zsh/config
. ~/.zsh/prompt
. ~/.zsh/welcome

# Have a system specific rcfile? Source it!
if [ -f ~/.localrc ]; then
    . ~/.localrc
fi

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" 
