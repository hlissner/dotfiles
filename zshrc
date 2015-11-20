### zshrc
# By Henrik Lissner <henrik@lissner.net>
# Uses zgen to manage plugins

DOTFILES=$HOME/.dotfiles

source $DOTFILES/zsh/functions.zsh
source $DOTFILES/zsh/aliases.zsh

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
        zgen load hchbaw/opp.zsh
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

export DOCKER_HOST=tcp://server:4243

export RUST_SRC_PATH=$HOME/Dropbox/lib/rust/src
export GOPATH=$HOME/Dropbox/work/go
export ANDROID_HOME=/usr/local/opt/android-sdk
export ANDROID_SDK=/usr/local/Cellar/android-sdk/24.2

# basictex
# export PATH=/usr/local/texlive/2015basic/bin/x86_64-darwin:$PATH

path=(
    $HOME/.dotfiles/scripts
    $HOME/.{rb,py}env/bin
    $GOPATH/bin
    $ANDROID_HOME/platform-tools
    $ANDROID_HOME/tools
    /usr/texbin
    $path
)

cache rbenv init - --no-rehash
cache pyenv init - --no-rehash

# Done!
