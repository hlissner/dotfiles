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
alias l='ls -1'
alias ll='ls -l'
alias la='ls -la'

# notify me before clobbering files
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias gurl='curl --compressed'
alias mkdir='mkdir -p'
alias rsyncd='rsync -va --delete'   # Hard sync two directories
alias wget='wget -c'                # Resume dl if possible

alias pubkey='cat ~/.ssh/id_rsa.pub'

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

alias ydl='youtube-dl'
alias ydl-aac='youtube-dl --extract-audio --audio-format aac'
alias ydl-m4a='youtube-dl --extract-audio --audio-format m4a'

alias ddg='duckduckgo'
alias bt='transmission-remote'

take() { mkdir "$1" && cd "$1"; }
hex()  { echo -n $@ | xxd -psdu; }

if command -v compdef >/dev/null; then
    compdef take=mkdir
fi
