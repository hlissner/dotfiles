export PHPENV_ROOT="$XDG_DATA_HOME/phpenv"
path=( $PHPENV_ROOT/bin $PHPENV_ROOT/shims $path )
_cache phpenv init - --no-rehash
