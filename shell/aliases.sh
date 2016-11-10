#
# These aliases will be common to Bash and Zsh shells
#

alias q='exit'
alias clr='clear'
alias sudo='sudo '

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias ln="${aliases[ln]:-ln} -v"  # verbose ln
alias ls="${aliases[ls]:-ls} --group-directories-first"
alias l='ls -l'
alias ll='ls -la'

alias pubkey='cat ~/.ssh/id_rsa.pub | y | echo "Public key copied to pasteboard."'

# For example, to list all directories that contain a certain file: find . -name
# .gitattributes | map dirname
alias map="xargs -n1"

take() { mkdir "$1" && cd "$1"; }
hex()  { echo -n $@ | xxd -psdu; }
