### ReDefs
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'
alias wget='wget -c'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias rg='noglob rg'
alias ag='noglob ag -p $HOME/.config/ag/agignore'


### convenience
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias q=exit
alias clr=clear
alias sudo='sudo '

alias exa='exa --group-directories-first'
alias l='exa -1'
alias ll='exa -l'
alias la='LC_COLLATE=C exa -la'
alias mk=make

alias rcp='rsync -vaP --delete'
alias rmirror='rsync -rtvu --delete'
alias gurl='curl --compressed'

alias sc=systemctl
alias ssc='sudo systemctl'

alias y='xclip -selection clipboard -in'
alias p='xclip -selection clipboard -out'


### Tools
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
