export LUAENV_ROOT="$XDG_DATA_HOME/luaenv"

path=( $LUAENV_ROOT/bin $path )
_cache luaenv init - --no-rehash
