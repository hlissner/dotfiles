#!/bin/bash

DOTFILES="$HOME/.dotfiles"
CACHE_DIR="$HOME/.cache"

is-callable() { command -v "$1" >/dev/null; }
is-interactive() { [[ $- == *i* ]]; }
is-root() { [[ "$UID" -eq 0 ]]; }
is-ssh() { [[ "$SSH_CONNECTION" != '' ]]; }

cache() {
    if [[ -z "$CACHE_DIR" ]]; then
        >&2 echo "Cache not set!"
        return 1
    fi

    [[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"

    is-callable "$1" || return 1
    local cache="${CACHE_DIR}/$1-$(basename $SHELL)"
    if ! [[ -f "$cache" && -s "$cache" ]]; then
        echo "Caching $1"
        $@ > "$cache" 2> /dev/null
    fi
    source $cache
}
