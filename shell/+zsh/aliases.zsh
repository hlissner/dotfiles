load shell/aliases.sh

#
autoload -U zmv

zman() { PAGER="less -g -s '+/^       "$1"'" man zshall; }
alias ag='noglob ag'

alias ddg='duckduckgo'
alias bt='transmission-remote'
alias ydl='youtube-dl'
alias ydls='youtube-dl --extract-audio --audio-format m4a'

# Canonical hex dump; some systems have this symlinked
is-callable hd || alias hd="hexdump -C"

