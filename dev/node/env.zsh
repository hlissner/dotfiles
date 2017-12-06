export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/config

export NODENV_ROOT=$XDG_DATA_HOME/nodenv
path=( $NODENV_ROOT/bin $path )
_cache nodenv init - --no-rehash
