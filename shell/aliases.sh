#
# These aliases are common to Bash and Zsh shells
#

alias q='exit'
alias clr='clear'
alias sudo='sudo '

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias ln="${aliases[ln]:-ln} -v"  # verbose ln
alias l='ls -l'
alias ll='ls -la'

# notify me before clobbering files
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias gurl='curl --compressed'
alias mkdir='mkdir -p'
alias rsyncd='rsync -va --delete'   # Hard sync two directories
alias wget='wget -c'                # Resume dl if possible

alias pubkey='cat ~/.ssh/id_rsa.pub'

alias yd='youtube-dl'
alias ydm='youtube-dl --extract-audio --audio-format aac'

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias mk='make'
alias exe='exercism'

# For example, to list all directories that contain a certain file: find . -name
# .gitattributes | map dirname
alias map="xargs -n1"

o() { open "${1:-.}" }
c() { cd "$1" && ls -l; }
take() { mkdir "$1" && cd "$1"; }
hex()  { echo -n $@ | xxd -psdu; }

if command -v compdef >/dev/null; then
    compdef o=open
    compdef c=cd
    compdef take=mkdir
fi
