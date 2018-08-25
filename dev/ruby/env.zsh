export GEMRC="$XDG_CONFIG_HOME/gems/rc:$GEMRC"
export GEM_HOME="$XDG_DATA_HOME/gems"
export GEM_SPEC_CACHE="$XDG_CACHE_HOME/gem/specs"
export IRBRC="$XDG_CONFIG_HOME/irb/rc"
export PRYRC="$XDG_CONFIG_HOME/pry/rc"
export SPEC_OPTS="--color --order random"

export RBENV_ROOT="$XDG_DATA_HOME/rbenv"
path=( $RBENV_ROOT/bin $GEM_HOME/bin $path )
_cache rbenv init - --no-rehash
