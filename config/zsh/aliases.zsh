alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias q=exit
alias clr=clear
alias sudo='sudo '
alias rm='rm -i'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias path='echo -e ${PATH//:/\\n}'
alias ports='netstat -tulanp'
alias mk=make
alias gurl='curl --compressed'

# An rsync that respects gitignore
function rcp {
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

autoload -U zmv

function mkcd { mkdir "$1" && cd "$1"; }; compdef mkcd=mkdir

function zman { PAGER="less -g -I -s '+/^       "$1"'" man zshall; }


# Systemd

alias jc='journalctl -xe'
alias jcu='journalctl -xe -u'
alias sc=systemctl
alias scu='systemctl --user'
alias scur='systemctl --user restart'
alias scus='systemctl --user status'
alias ssc='sudo systemctl'
alias sscr='sudo systemctl restart'
alias sscs='sudo systemctl status'
alias rctl='sudo resolvectl'
alias nctl='sudo networkctl'
alias bctl='bluetoothctl'

alias nonet='systemd-run --user --property=PrivateNetwork=yes --same-dir --pty'


# External programs

if (( $+commands[eza] )); then
  alias exa="eza --group-directories-first --git";
  alias l="eza -blF --icons";
  alias ll="eza -abghilmu";
  alias llm='ll --sort=modified'
  alias la="LC_COLLATE=C eza -ablF";
  alias tree='eza --tree'
fi

if (( $+commands[nix] )); then
  alias n=nix
  alias ne=nix-env
  alias nf='nix flake'
  alias nfm='nix flake metadata'
  alias nfs='nix flake show'
  alias nr='nix repl'
  alias nrp='nix repl "<nixpkgs>"'
  alias ns='nix search'
  alias nsp='nix search nixpkgs'
fi
