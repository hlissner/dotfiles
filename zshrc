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

if is-callable 'rbenv'; then
    export PATH=~/.rbenv/bin:$PATH
    eval "$(rbenv init - --no-rehash)"
fi

if is-callable 'pyenv'; then
    export PATH=~/.pyenv/bin:~/.pyenv/shims:$PATH
    eval "$(pyenv init - --no-rehash)"
fi
