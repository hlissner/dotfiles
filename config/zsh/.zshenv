for dir in $XDG_CONFIG_HOME/*/bin(N); do
  export PATH="$dir:$PATH"
done

for file in $XDG_CONFIG_HOME/*/env.zsh(N); do
  source $file
done

# If you have host-local configuration, this is where you'd put it
[ -f ~/.config/zsh/env ] && source ~/.config/zsh/env
