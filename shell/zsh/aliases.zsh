autoload -U zmv

zman() { PAGER="less -g -s '+/^       "$1"'" man zshall; }

r() {
  local time=$1; shift
  sched "$time" "notify-send --urgency=critical 'Reminder' '$@'; ding";
}; compdef r=sched

# aliases common to all shells
alias q=exit
alias clr=clear
alias sudo='sudo '

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias ln="${aliases[ln]:-ln} -v"  # verbose ln
alias l='ls -1'
alias ll='ls -l'
alias la='LC_COLLATE=C ls -la'

# notify me before clobbering files
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias gurl='curl --compressed'
alias mkdir='mkdir -p'
alias rsyncd='rsync -va --delete'   # Hard sync two directories
alias wget='wget -c'                # Resume dl if possible

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias ag="noglob ag -p $XDG_CONFIG_HOME/ag/agignore"
alias rg='noglob rg'

# For example, to list all directories that contain a certain file: find . -name
# .gitattributes | map dirname
alias map="xargs -n1"

# Convenience
alias kb=keybase
alias mk=make
alias exe=exercism
alias ydl=youtube-dl
alias ydl-aac='youtube-dl --extract-audio --audio-format aac'
alias ydl-m4a='youtube-dl --extract-audio --audio-format m4a'
alias ddg=duckduckgo
alias bt=transmission-remote

take() { mkdir "$1" && cd "$1"; }; compdef take=mkdir
hex()  { echo -n $@ | xxd -psdu; }
