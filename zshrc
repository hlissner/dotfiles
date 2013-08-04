# ZSH Env variables
export ZSH=$HOME/.oh-my-zsh

source ~/.zsh/functions

# Plugins:
#  see <https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins>
plugins=(vi-mode ruby python composer git)
if is_mac; then
    plugins+=brew
    plugins+=tmux
    plugins+=vagrant
fi

# Liiiiive!
source $ZSH/oh-my-zsh.sh

# Source component rcfiles
source ~/.zsh/aliases
source ~/.zsh/config
source ~/.zsh/completion
source ~/.zsh/prompt
source ~/.zsh/welcome

# Have a system specific rcfile? Source it!
[ -f ~/.localrc ] && source ~/.localrc

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" 
