function is-callable {
  (( $+commands[$1] )) || (( $+functions[$1] )) || (( $+aliases[$1] ))
}

# Source component rcfiles
if [[ -z "$EMACS" ]]; then
    source ~/.zsh/zgen/zgen.zsh
    if ! zgen saved; then
        echo "Creating zgen save"
    
        zgen load zsh-users/zsh-syntax-highlighting
        zgen load zsh-users/zsh-history-substring-search
        zgen load zsh-users/zsh-completions src
        zgen load clvv/fasd
        zgen load hchbaw/opp.zsh
        zgen load Tarrasch/zsh-bd
        zgen load houjunchen/zsh-vim-mode
    
        zgen save
    fi
    
    source ~/.zsh/aliases.zsh
    source ~/.zsh/config.zsh
    source ~/.zsh/keybinds.zsh
    source ~/.zsh/prompt.zsh

    fasd_cache="$HOME/.fasd-cache"
    if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
        fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install >| "$fasd_cache"
    fi
    source "$fasd_cache"
    unset fasd_cache
fi

## PATHS ###############################################
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
