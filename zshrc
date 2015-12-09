### zshrc
# By Henrik Lissner <henrik@lissner.net>
# Uses zgen to manage plugins

DOTFILES=$HOME/.dotfiles

source $DOTFILES/zsh/functions.zsh

# if not running through emacs' shell-command
if [ ! $TERM = dumb ]; then
    ZGEN_AUTOLOAD_COMPINIT=true
    if [[ "${USER}" == "root" ]]; then
        ZGEN_AUTOLOAD_COMPINIT=false
    fi

    source ~/.zsh/zgen/zgen.zsh
    if ! zgen saved; then
        echo "Creating zgen save"

        zgen load zsh-users/zsh-syntax-highlighting
        zgen load zsh-users/zsh-history-substring-search
        zgen load zsh-users/zsh-completions src
        zgen load Tarrasch/zsh-bd
        zgen load houjunchen/zsh-vim-mode

        zgen load $DOTFILES/zsh/config.zsh
        zgen load $DOTFILES/zsh/completion.zsh
        zgen load $DOTFILES/zsh/keybinds.zsh
        zgen load $DOTFILES/zsh/prompt.zsh

        zgen save
    fi

    cache fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install
fi

source $DOTFILES/zsh/aliases.zsh

cache rbenv init - --no-rehash
cache pyenv init - --no-rehash

# Done!
