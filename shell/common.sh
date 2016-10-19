#!/bin/bash

CACHE_DIR="$DOTFILES/shell/zsh/cache"

is-callable() { command -v "$1" >/dev/null; }
is-interactive() { [[ $- == *i* ]]; }
is-root() { [[ "$UID" -eq 0 ]]; }
is-ssh()  { [[ "$SSH_CONNECTION" != '' ]]; }

info()    { printf "\r[ \033[00;34m..\033[0m ] $1\n"; }
success() { printf "\r\033[2K[ \033[00;32mOK\033[0m ] $1\n"; }
fail()    { printf "\r\033[2K[\033[0;31mFAIL\033[0m] $1\n"; echo; exit; }

load () { source "$DOTFILES/$*"; }

loadall () {
    for file in "$DOTFILES"/$1/*.zsh;
    do
        source "$file"
    done
}

cache() {
    [ -z "$CACHE_DIR" ] && error "Cache not set!"
    [ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR"

    is-callable "$1" || return 1
    local cache="${CACHE_DIR}/$1-$(basename $SHELL)"
    if ! [[ -f "$cache" && -s "$cache" ]]; then
        echo "Caching $1"
        $@ > "$cache" 2> /dev/null
    fi
    source $cache
}

cache-clear() {
    [ -d "$CACHE_DIR" ] && rm -f "$CACHE_DIR/*"
}

repo() {
    if [ ! -d "$2" ];
    then
        git clone "https://github.com/$1" "$2"
    fi
}
