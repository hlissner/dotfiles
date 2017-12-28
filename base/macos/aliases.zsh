alias ls="gls --color=auto --group-directories-first"
alias date=gdate

alias y=pbcopy
alias p=pbpaste

alias br=brew
alias bru='brew update && brew upgrade && brew cleanup'
alias brc='brew cask'

# OS X has no `md5sum`, so use `md5` as a fallback
_is_callable md5sum  || alias md5sum="md5"
# OS X has no `sha1sum`, so use `shasum` as a fallback
_is_callable sha1sum || alias sha1sum="shasum"
