# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source ~/.zsh/preztorc
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Source component rcfiles
if [[ -z "$EMACS" ]]; then
    source ~/.zsh/config
    is-callable 'fasd' && eval "$(fasd --init auto)"
fi

source ~/.zsh/aliases

# Initialize rbenv and pyenv; rehashing slows down zsh startup, so we
# disable it.
if is-callable 'rbenv'; then
    eval "$(rbenv init - --no-rehash)"
fi
if is-callable 'pyenv'; then
    eval "$(pyenv init - --no-rehash)"
    eval "$(pyenv virtualenv-init -)"
fi
# if is-callable 'go'; then
#     export GOPATH="$HOME/Dropbox/Projects/dev/go"
#     export PATH="$GOPATH/bin:$PATH"
# fi
# if is-callable 'haxe'; then
#     export HAXE_STD_PATH="/usr/local/lib/haxe/std"
# fi
