#!/usr/bin/env zsh
# Everything .zshrc assumes is already true before it runs.
#
# On my own machines this file is very nearly a no-op: /etc/zshenv got here
# first with all of it (modules/{home,hey,shell/zsh}.nix). Elsewhere nothing
# does, which is what made this config unshippable -- see bin/infect.zsh, which
# symlinks this to a remote's ~/.zshenv and lets it bootstrap the rest.

_zdir=${${(%):-%x}:A:h}

: ${XDG_CONFIG_HOME:=$HOME/.config}
: ${XDG_CACHE_HOME:=$HOME/.cache}
: ${XDG_DATA_HOME:=$HOME/.local/share}
: ${XDG_STATE_HOME:=$HOME/.local/state}
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

: ${ZDOTDIR:=$_zdir}
export ZDOTDIR

# programs.zsh.histFile sets this
: ${HISTFILE:=$XDG_STATE_HOME/zsh/history}
export HISTFILE

# systemd.user.tmpfiles does this at home (see modules/shell/zsh.nix)
[[ -d ${HISTFILE:h} && -d $XDG_CACHE_HOME/zsh ]] ||
  mkdir -p -m 700 ${HISTFILE:h} $XDG_CACHE_HOME/zsh

# hey.cache and friends, from modules/hey.nix
if (( ! $+functions[hey.cache] )) && [[ -d $_zdir/lib ]]; then
  fpath=( $_zdir/lib $_zdir/lib/completions $fpath )
  autoload -Uz $_zdir/lib/hey.*(N.:t)
fi

unset _zdir
