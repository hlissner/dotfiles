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
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias path='echo -e ${PATH//:/\\n}'
alias ports='netstat -tulanp'

alias mk=make
alias gurl='curl --compressed'

alias shutdown='sudo shutdown'
alias reboot='sudo reboot'

# An rsync that respects gitignore
rcp() {
  # -a = -rlptgoD
  #   -r = recursive
  #   -l = copy symlinks as symlinks
  #   -p = preserve permissions
  #   -t = preserve mtimes
  #   -g = preserve owning group
  #   -o = preserve owner
  # -z = use compression
  # -P = show progress on transferred file
  # -J = don't touch mtimes on symlinks (always errors)
  rsync -azPJ \
    --include=.git/ \
    --filter=':- .gitignore' \
    --filter=":- $XDG_CONFIG_HOME/git/ignore" \
    "$@"
}; compdef rcp=rsync
alias rcpd='rcp --delete --delete-after'
alias rcpu='rcp --chmod=go='
alias rcpdu='rcpd --chmod=go='

alias y='xclip -selection clipboard -in'
alias p='xclip -selection clipboard -out'

alias jc='journalctl -xe'
alias sc=systemctl
alias ssc='sudo systemctl'

if (( $+commands[exa] )); then
  alias exa="exa --group-directories-first --git";
  alias l="exa -blF";
  alias ll="exa -abghilmu";
  alias llm='ll --sort=modified'
  alias la="LC_COLLATE=C exa -ablF";
  alias tree='exa --tree'
fi

if (( $+commands[fasd] )); then
  # fuzzy completion with 'z' when called without args
  unalias z 2>/dev/null
  function z {
    [ $# -gt 0 ] && _z "$*" && return
    cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
  }
fi

autoload -U zmv

function take {
  mkdir "$1" && cd "$1";
}; compdef take=mkdir

function zman {
  PAGER="less -g -I -s '+/^       "$1"'" man zshall;
}

# Create a reminder with human-readable durations, e.g. 15m, 1h, 40s, etc
function r {
  local time=$1; shift
  sched "$time" "notify-send --urgency=critical 'Reminder' '$@'; ding";
}; compdef r=sched
