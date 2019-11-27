source $ZGEN_SOURCE

if ! zgen saved; then
  echo "Initializing zgen"

  zgen load hlissner/zsh-autopair autopair.zsh
  zgen load zsh-users/zsh-history-substring-search
  zgen load zdharma/history-search-multi-word
  zgen load zsh-users/zsh-completions src
  zgen load junegunn/fzf shell

  if [[ -z $SSH_CONNECTION ]]; then
    zgen load zdharma/fast-syntax-highlighting
  fi

  zgen save
fi

source $ZDOTDIR/prompt.zsh
source $ZDOTDIR/config.zsh
source $ZDOTDIR/keybinds.zsh
source $ZDOTDIR/completion.zsh
source $ZDOTDIR/aliases.zsh
for file in $XDG_CONFIG_HOME/zsh/rc.d/aliases.*.zsh(N); do
  source $file
done

if [[ -f ~/.config/zsh/rc ]]; then
  source ~/.config/zsh/rc
fi


##
function _cache {
  command -v "$1" >/dev/null || return 1
  local cache_dir="$XDG_CACHE_HOME/${SHELL##*/}"
  local cache="$cache_dir/$1"
  if [[ ! -f $cache || ! -s $cache ]]; then
    echo "Caching $1"
    mkdir -p $cache_dir
    "$@" >$cache
  fi
  source $cache || rm -f $cache
}

# fd > find
if command -v fd >/dev/null; then
  export FZF_DEFAULT_OPTS="--reverse --ansi"
  export FZF_DEFAULT_COMMAND="fd ."
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd -t d . $HOME"
fi

_cache fasd --init posix-alias zsh-{hook,{c,w}comp{,-install}}
_cache direnv hook zsh


##
autoload -Uz compinit && compinit -u -d $ZSH_CACHE/zcompdump
autopair-init
