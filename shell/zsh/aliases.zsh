#!/usr/bin/env zsh

load shell/aliases.sh


zman() { PAGER="less -g -s '+/^       "$1"'" man zshall; }
alias \?='since @$last'

## Compilers, interpretors 'n builders #######################################
alias mk='make'
alias exe='exercism'

## Redefined tools ###########################################################
# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias ag='noglob ag'
alias gurl='curl --compressed'
alias mkdir='mkdir -p'
alias rsyncd='rsync -va --delete'   # Hard sync two directories
alias ssh='ssh -C'                  # Compression for all ssh connections
alias wget='wget -c'                # Resume dl if possible
alias ydl='youtube-dl'

## New tools #################################################################

# Canonical hex dump; some systems have this symlinked
is-callable hd || alias hd="hexdump -C"

## Remote resources ##########################################################
# URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'
# find conflicted dropbox files
alias findc="find . -iname '*conflicted*' -type f -exec echo '\"{}\" ' \;"
# Send to sprunge.us
alias bin="curl -s -F 'sprunge=<-' http://sprunge.us | head -n 1 | tr -d '\r\n ' | y"
# IP addresses
alias publicip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
# View HTTP traffic
alias sniff="sudo ngrep -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en0 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""
# Make URL REQUEST shortcuts
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    alias "$method"="lwp-request -m '$method'"
done
