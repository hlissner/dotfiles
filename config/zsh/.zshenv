export ZGEN_DIR="$XDG_CACHE_HOME/zgen"
export ZGEN_SOURCE="$ZGEN_DIR/zgen.zsh"

for dir in $XDG_CONFIG_HOME/*/bin(N); do
  export PATH="$dir:$PATH"
done

for file in $XDG_CONFIG_HOME/zsh/rc.d/env.*.zsh(N); do
  source $file
done

# If you have host-local configuration, this is where you'd put it
[ -f ~/.config/zsh/env ] && source ~/.config/zsh/env
