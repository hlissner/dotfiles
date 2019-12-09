export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZSH_CACHE="$XDG_CACHE_HOME/zsh"
export ZGEN_DIR="$XDG_CACHE_HOME/zgen"
export ZGEN_SOURCE="$ZGEN_DIR/zgen.zsh"

if [[ ! -d "$ZGEN_SOURCE" ]]; then
  git clone https://github.com/tarjoilija/zgen "$ZGEN_DIR"
fi

for dir in $XDG_CONFIG_HOME/*/bin(N); do
  export PATH="$dir:$PATH"
done

for file in $XDG_CONFIG_HOME/zsh/rc.d/env.*.zsh(N); do
  source $file
done

# If you have host-local configuration, this is where you'd put it
[ -f ~/.config/zsh/env ] && source ~/.config/zsh/env
