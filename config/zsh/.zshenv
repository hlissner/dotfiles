for file in $XDG_CONFIG_HOME/zsh/rc.d/env.*.zsh(N); do
  source $file
done

if [[ -f ~/.config/zsh/env ]]; then
  source ~/.config/zsh/env
fi
