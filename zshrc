### zshrc
# By Henrik Lissner <henrik@lissner.net>

if [ ! -d ~/.zgen ]; then
    echo "Zgen isn't installed! Run install.sh"
    exit 1
fi

TMUXIFIER="$HOME/.tmuxifier"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

source ~/.zgen/zgen.zsh
if ! zgen saved; then
    echo "Creating zgen save"
    [[ -d "$CACHE_DIR" ]] && rm -f "$CACHE_DIR/*"

    zgen load thewtex/tmux-mem-cpu-load
    zgen load joepvd/zsh-hints

    zgen load hlissner/zsh-autopair "autopair.zsh"
    zgen load zsh-users/zsh-history-substring-search
    zgen load zsh-users/zsh-completions src
    is-ssh || zgen load zsh-users/zsh-syntax-highlighting

    zgen save
fi

source ~/.zsh/config
if is-interactive; then
    source ~/.zsh/keybinds
    source ~/.zsh/prompt
    source ~/.zsh/completion
fi

cache rbenv init - --no-rehash
cache pyenv init - --no-rehash
if is-interactive; then
    cache fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install
    cache tmuxifier init -
fi

source ~/.zsh/aliases

# Done!
