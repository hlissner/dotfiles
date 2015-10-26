### zshrc
# By Henrik Lissner <henrik@lissner.net>
# Uses zgen to manage plugins

source ~/.zsh/functions.zsh
source ~/.zsh/aliases.zsh

# if not running through emacs' shell-command
if [ -z "$EMACS" ]; then
    source ~/.zsh/zgen/zgen.zsh
    if ! zgen saved; then
        echo "Creating zgen save"

        zgen load zsh-users/zsh-syntax-highlighting
        zgen load zsh-users/zsh-history-substring-search
        zgen load zsh-users/zsh-completions src
        zgen load hchbaw/opp.zsh
        zgen load Tarrasch/zsh-bd
        zgen load houjunchen/zsh-vim-mode

        zgen save
    fi

    source ~/.zsh/config.zsh
    source ~/.zsh/completion.zsh
    source ~/.zsh/keybinds.zsh
    source ~/.zsh/prompt.zsh

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
    $HOME/.dotfiles/bin
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
