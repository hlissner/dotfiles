alias q='exit'
alias clr='clear'
alias sudo='sudo '

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias ls="${aliases[ls]:-ls} --group-directories-first"
alias l='ls -l'
alias ll='ls -la'

alias ln='ln -v'  # verbose ln
