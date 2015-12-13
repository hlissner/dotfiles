is-callable() {
    (( $+commands[$1] )) || (( $+functions[$1] )) || (( $+aliases[$1] ))
}

ZSH_CACHE_DIR="$HOME/.zsh/cache/$(hostname)"
[[ ! -d "$ZSH_CACHE_DIR" ]] && mkdir -p "$ZSH_CACHE_DIR"

cache() {
    is-callable "$1" || return 1
    local cache="${ZSH_CACHE_DIR}/$1-cache"
    if [[ ! -s "$cache" ]]; then
        echo "Caching $1"
        $@ >| "$cache" 2> /dev/null
    fi
    source $cache
    unset cache
}

is-mac() {
    [[ "$OSTYPE" == "darwin"* ]]
}

is-deb() {
    [[ "$OSTYPE" == "linux-gnu" ]]
}

is-cygwin() {
    [[ "$OSTYPE" == "cygwin"* ]]
}

fpath=("${0:h}/functions" $fpath)
