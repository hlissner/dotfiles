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

alias reload='source /run/current-system/etc/set-environment'
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

if (( $+commands[wl-copy] )); then
  alias y='wl-copy'
  alias p='wl-paste'
elif (( $+commands[xclip] )); then
  alias y='xclip -selection clipboard -in'
  alias p='xclip -selection clipboard -out'
fi

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

if (( $+commands[eza] )); then
  alias exa="eza --group-directories-first --git";
  alias l="eza -blF --icons";
  alias ll="eza -abghilmu";
  alias llm='ll --sort=modified'
  alias la="LC_COLLATE=C eza -ablF";
  alias tree='eza --tree'
fi

if (( $+commands[fasd] && $+commands[fzf] )); then
  # fuzzy completion with 'z' when called without args
  (( $+aliases[z] )) && unalias z
  function z {
    if (( $# > 0 )); then
      fasd_cd -d $@
    else
      local dir=$(fasd_cd -d -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')
      [[ -n $dir ]] && cd $dir
    fi
  }
fi

if (( $+commands[udisksctl] )); then
  alias ud='udisksctl'
  alias udm='udisksctl mount -b'
  alias udu='udisksctl unmount -b'
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

if (( $+commands[swayimg] )); then
  alias -s {jpg,jpeg,gif,png,svg}=swayimg
elif (( $+commands[feh] )); then
  alias -s {jpg,jpeg,gif,png,svg}=feh
fi

if (( $+commands[mpv] )); then
  alias -s {mp4,avi,mkv,mov}=mpv
fi

if (( $+commands[xdg-open] )); then
  alias open=xdg-open
fi

if (( $+commands[img2sixel] )); then
  alias six=img2sixel
fi

autoload -U zmv

function mkcd { mkdir "$1" && cd "$1"; }; compdef mkcd=mkdir

function zman { PAGER="less -g -I -s '+/^       "$1"'" man zshall; }
