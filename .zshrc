# Init ZSH
ZSH=$HOME/.oh-my-zsh

plugins=(git osx ruby python iterm brew vundle syntax-highlighting)


#######################
# Options

COMPLETION_WAITING_DOTS="true"

export PATH=~/Dropbox/dev/bin:/usr/local/bin:/usr/local/sbin:`brew --prefix coreutils`/libexec/gnubin:$PATH

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" 
PATH=$PATH:$HOME/.rvm/bin

export EDITOR='vim'
export RUBYOPT=rubygems
# export CC=gcc-4.2
export CPPFLAGS=-I/opt/X11/include

source $ZSH/oh-my-zsh.sh

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2)" scp sftp ssh

#######################
# Aliases

alias zrc='vim ~/.zshrc'

# Directories
alias dev='cd /usr/local/dev'
alias w='cd ~/Work/'
alias wd='cd ~/Work/Dev'
alias wp='cd ~/Work/Projects/'

# Apps
alias g='git'
alias v='mvim'

# Git aliases
alias ga='g a'
alias gc='g c'
alias gs='g s'
alias gd='g d'


#######################
# Prompt

PROMPT="
%{$FX[bold]%}%{$fg[cyan]%}%{$BG[234]%}> "
RPROMPT="%~$(git_prompt_info) : $(hostname)%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX="["
ZSH_THEME_GIT_PROMPT_SUFFIX="]"
