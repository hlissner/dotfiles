# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source ~/.zsh/preztorc
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
else
    echo "Prezto isn't installed! Run ~/.dotfiles/install.sh"
    exit 1
fi

source ~/.zsh/aliases

# Source component rcfiles
if [[ -z "$EMACS" ]]; then
    source ~/.zsh/config
    is-callable 'fasd' && eval "$(fasd --init auto)"
fi

if [ -d ~/.rbenv ]; then
    export PATH=~/.rbenv/bin:$PATH
    eval "$(rbenv init - --no-rehash)"
fi

if [ -d ~/.pyenv ]; then
    export PATH=~/.pyenv/bin:~/.pyenv/shims:$PATH
    eval "$(pyenv init - --no-rehash)"
fi

export ANDROID_HOME=/usr/local/opt/android-sdk
export ANDROID_SDK=/usr/local/Cellar/android-sdk/24.2
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH

export CPPFLAGS="-I/usr/local/include"
export LDFLAGS="-L/usr/local/lib -L/usr/local/opt/sqlite/lib"
