### zshrc
# By Henrik Lissner <henrik@lissner.net>
# Uses zgen to manage plugins

DOTFILES=$HOME/.dotfiles

ZSH_CACHE_DIR="$HOME/.zsh/cache/$(hostname)"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# if not running through emacs' shell-command
if [ ! $TERM = dumb ]; then
    ZGEN_AUTOLOAD_COMPINIT=true
    [[ "${USER}" == "root" ]] && ZGEN_AUTOLOAD_COMPINIT=false

    source ~/.zsh/zgen/zgen.zsh
    if ! zgen saved; then
        echo "Creating zgen save"

        zgen load zsh-users/zsh-history-substring-search
        zgen load willghatch/zsh-hooks
        zgen load hlissner/zsh-autopair
        zgen load StackExchange/blackbox
        [[ "$SSH_CONNECTION" == '' ]] && zgen load zsh-users/zsh-syntax-highlighting

        zgen load zsh-users/zsh-completions src

        zgen load "$DOTFILES/zsh/config.zsh"
        zgen load "$DOTFILES/zsh/completion.zsh"
        zgen load "$DOTFILES/zsh/keybinds.zsh"
        zgen load "$DOTFILES/zsh/prompt.zsh"

        zgen save
    fi

    cache fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install

    export FZF_DEFAULT_COMMAND='ag -g ""'
    export FZF_DEFAULT_OPTS='--reverse --inline-info'
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

source "$DOTFILES/zsh/aliases.zsh"

cache rbenv init - --no-rehash
cache pyenv init - --no-rehash

# Done!
