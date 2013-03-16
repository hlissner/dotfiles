# Init ZSH
ZSH=$HOME/.oh-my-zsh
plugins=(laravel ruby python brew)
source $ZSH/oh-my-zsh.sh

# Source component rcfiles
source ~/.zsh/functions
source ~/.zsh/paths
source ~/.zsh/aliases
source ~/.zsh/config
source ~/.zsh/completion
source ~/.zsh/prompt
source ~/.zsh/welcome

# Have a system specific rcfile? Source it!
if [ -f ~/.localrc ]; then
    source ~/.localrc
fi

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" 
