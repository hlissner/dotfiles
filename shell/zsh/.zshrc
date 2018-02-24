export ZGEN_AUTOLOAD_COMPINIT=0
AUTOPAIR_INHIBIT_INIT=1

_load_repo tarjoilija/zgen $ZGEN_DIR zgen.zsh
if ! zgen saved; then
  echo "Creating zgen save"
  _cache_clear

  zgen load hlissner/zsh-autopair autopair.zsh develop
  zgen load zsh-users/zsh-history-substring-search
  zgen load zdharma/history-search-multi-word
  zgen load zsh-users/zsh-completions src
  zgen load junegunn/fzf shell  # completions

  if [[ -z $SSH_CONNECTION ]]; then
    zgen load zdharma/fast-syntax-highlighting
  fi

  zgen save
fi

_load shell/zsh/prompt.zsh
_load shell/zsh/config.zsh
_load shell/zsh/completion.zsh
_load shell/zsh/keybinds.zsh

#
autoload -Uz compinit && compinit -d $ZSH_CACHE/zcompdump
_load_all aliases.zsh

#
export _FASD_DATA="$XDG_CACHE_HOME/fasd"
export _FASD_VIMINFO="$XDG_CACHE_HOME/viminfo"
_cache fasd --init posix-alias zsh-{hook,{c,w}comp{,-install}}
autopair-init

# vim:set ft=sh:
