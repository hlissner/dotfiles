DOTFILES="$HOME/.dotfiles"
CACHE_DIR="$HOME/.cache/${ZSH_NAME:-sh}"
ENABLED_DIR="$DOTFILES/.enabled.d"

is-callable() { command -v "$1" >/dev/null; }
is-interactive() { [[ $- == *i* ]]; }
is-root() { [[ "$UID" -eq 0 ]]; }

info()    { printf "\r[ \033[00;34m..\033[0m ] $1\n"; }
success() { printf "\r\033[2K[ \033[00;32mOK\033[0m ] $1\n"; }
fail()    { printf "\r\033[2K[\033[0;31mFAIL\033[0m] $1\n"; echo; exit; }

load () { source "$DOTFILES/$1"; }

loadall () {
    local files=( "$ENABLED_DIR"/*/"${1:-*.*sh}" )
    for file in "${files[@]}"; do
        [[ -e "$file" ]] && source "$file"
    done
}

cache() {
    [[ -z "$CACHE_DIR" ]] && error "Cache not set!"
    [[ -d "$CACHE_DIR" ]] || mkdir -p "$CACHE_DIR"

    is-callable "$1" || return 1
    local cache="${CACHE_DIR}/$1-${SHELL##*/}"
    if [[ ! -f "$cache" || ! -s "$cache" ]]; then
        echo "Caching $1"
        $@ > "$cache" 2> /dev/null
    fi
    source $cache
}

cache-clear() {
    [[ -d $CACHE_DIR ]] && rm -f "$CACHE_DIR/*"
}

repo() {
    [[ -d $2 ]] || git clone --recursive "https://github.com/$1" "$2"
}

#
load shell/env.sh
