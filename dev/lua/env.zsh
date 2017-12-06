export LUAENV_ROOT="$XDG_DATA_HOME/luaenv"

path=( $LUAENV_ROOT/bin $path )
.cache luaenv init - --no-rehash
