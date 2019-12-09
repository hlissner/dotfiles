alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias q=exit
alias clr=clear
alias sudo='sudo '

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'
alias wget='wget -c'
alias rg='noglob rg'
alias bc='bc -lq'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

if command -v exa >/dev/null; then
  alias exa='exa --group-directories-first'
  alias l='exa -1'
  alias ll='exa -l'
  alias la='LC_COLLATE=C exa -la'
else
  alias l='ls -1'
  alias ll='ls -l'
fi

alias mk=make
alias rcp='rsync -vaP --delete'
alias rmirror='rsync -rtvu --delete'
alias gurl='curl --compressed'

alias y='xclip -selection clipboard -in'
alias p='xclip -selection clipboard -out'

alias sc=systemctl
alias ssc='sudo systemctl'

alias nix-env='NIXPKGS_ALLOW_UNFREE=1 nix-env'
alias nen=nix-env
alias nch=nix-channel
alias ngc='nix-collect-garbage -d'
alias nre='sudo nixos-rebuild'
alias nup='sudo nix-channel --update && nre'

if command -v nvim >/dev/null; then
  alias vim=nvim
  alias v=nvim
fi

autoload -U zmv

take() {
  mkdir "$1" && cd "$1";
}; compdef take=mkdir

zman() {
  PAGER="less -g -s '+/^       "$1"'" man zshall;
}

r() {
  local time=$1; shift
  sched "$time" "notify-send --urgency=critical 'Reminder' '$@'; ding";
}; compdef r=sched
