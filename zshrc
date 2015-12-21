### zshrc
# By Henrik Lissner <henrik@lissner.net>

############################################

# Light mode are for remote shells or computers where I don't have much access, and
# therefore cannot install most of my zsh plugins (though can somehow get away with using
# zsh itself).

LIGHTMODE=

############################################

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_PLUGINS_ALIAS_TIPS_EXPAND=1
ZGEN_AUTOLOAD_COMPINIT=true
[[ "${USER}" == "root" ]] && ZGEN_AUTOLOAD_COMPINIT=false

load zsh/zgen/zgen.zsh
if ! zgen saved; then
    echo "Creating zgen save"
    [[ -d "$CACHE_DIR" ]] && rm -f "$CACHE_DIR/*"

    zgen load StackExchange/blackbox
    zgen load thewtex/tmux-mem-cpu-load
    zgen load djui/alias-tips
    zgen load joepvd/zsh-hints
    zgen load unixorn/git-extra-commands

    zgen load hlissner/zsh-autopair "autopair.zsh"
    zgen load zsh-users/zsh-history-substring-search
    is-ssh || zgen load zsh-users/zsh-syntax-highlighting
    zgen load zsh-users/zsh-completions src

    zgen save
fi

cache rbenv init - --no-rehash
cache pyenv init - --no-rehash
if is-interactive; then
    cache fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install

    export FZF_DEFAULT_COMMAND='ag -g ""'
    export FZF_DEFAULT_OPTS='--reverse --inline-info'
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

load  zsh/config
iload zsh/keybinds
iload zsh/prompt
load  zsh/aliases
iload zsh/completion

# Done!
