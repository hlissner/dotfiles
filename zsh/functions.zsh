is-callable() {
    (( $+commands[$1] )) || (( $+functions[$1] )) || (( $+aliases[$1] ))
}

cache() {
    is-callable "$1" || return 1
    local cache="$HOME/.zsh/cache/$1-cache"
    if [ ! -s "$cache" ]; then
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
