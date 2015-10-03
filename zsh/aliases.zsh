alias q=exit
alias clr=clear
alias sudo='sudo '

# Tools
alias ag='nocorrect noglob ag'
alias l="ls -l"
alias ll="ls -1"
alias la="ls -la"
alias ln="ln -v"                    # Verbose ln
alias wget='wget -c'                # Resume dl if possible
alias rsyncd='rsync -va --delete'   # Hard sync two directories
alias mkdir='mkdir -p'
zman() { PAGER="less -g -s '+/^       "$1"'" man zshall; }
mkd()  { mkdir "$1" && cd "$1"; }

j() {
  local fasd_ret="$(fasd -i -d "$@")"
  if [[ -d "$fasd_ret" ]]; then
    cd "$fasd_ret"
  else
    print "$fasd_ret"
  fi
}

# transmission-remote
if is-callable 'transmission-remote'; then
    alias bt='transmission-remote server'
    alias bt-clear='bt -t all -r'

    # pretty print torrent list on remote server
    btl() {
        local results
        results=`transmission-remote server -l | \
            awk 'NR > 1 { s = ""; for (i = 10; i <= NF; i++) s = s $i " "; print $9 " | " s  }' | \
            sed '$d' | \
            perl -pe 's/\s\[[a-zA-Z0-9]+\]\s/ /g'`

        if [ -z "$results" ]; then
            echo "No torrents!"
        else
            echo $results
        fi
    }
fi

# Editors
v() { vim ${@:-.}; }             # Open in vim
e() { emacsclient -n ${@:-.}; }  # Open in emacs (daemon)
ee() { # emacs in project root
    if git root 2>/dev/null; then
        e "$(git rev-parse --show-toplevel)"
    else
        e .
    fi
}

# Compilers, interpretors 'n builders
alias va='vagrant'
alias py='python'
alias pye='pyenv'
alias rb='ruby'
alias rbe='rbenv'
alias b='bundle'
alias be='bundle exec'
alias bi='bundle install -path vendor'
alias ans='ansible'
alias ansp='ansible-playbook'
alias fabg='noglob fab -f ~/.dotfiles/ansible/fabfile.py'
alias rk='noglob rake'
alias rkg='noglob rake -g'
alias m='make'
alias c11='clang++ -std=c++11'
alias dk='docker'

# GIT
is-callable 'hub' && alias git='hub'
g() { [ $# -eq 0 ] && git status --short || git $* }

alias gi='git init'
alias gs='git status'
alias gsu='git submodule'
alias gco='git checkout'
alias gc='git commit'
alias gcm='noglob git commit -m'
alias gcma='noglob git commit --amend -m'
alias gd='git diff'
alias gp='git push'
alias gpl='git pull'
alias ga='git add'
alias ge='git exec'
alias gb='git branch'
alias gap='git add --patch'
alias gr='git reset "HEAD^"'
alias gre='git remote'

# Tmux
if is-callable 'tmux'; then
    alias t='tmux'
    alias ts='tmux send-keys'
    alias tl='tmux list-sessions'
    alias ta='tmux attach'

    if [ -n $TMUX ]; then
        # Detach all other clients to this session
        alias takeover='tmux detach -a'
    fi

    # Start new session or create a grouped session so I'm not simply watching
    # the same session in both windows.
    tdup() {tmux new-session -t $1}
fi

if is-mac; then
    alias ls="ls -G"

    alias c11='clang++ -std=c++11 -stdlib=libc++'
    alias eclimd='/Applications/eclipse/eclimd'

    # Homebrew
    alias br='brew'
    alias bru='brew update && brew upgrade --all'
    alias brc='brew cask'
    alias codekit='open -a CodeKit'
elif is-cygwin; then
    alias open='cygstart'
    alias pbcopy='tee > /dev/clipboard'
    alias pbpaste='cat /dev/clipboard'
else
    alias open='xdg-open'
    alias ls="ls --color=auto"

    if (( $+commands[xclip] )); then
        alias pbcopy='xclip -selection clipboard -in'
        alias pbpaste='xclip -selection clipboard -out'
    elif (( $+commands[xsel] )); then
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
    fi
fi

# By default, open cwd
o() { open ${@:-.}; }
