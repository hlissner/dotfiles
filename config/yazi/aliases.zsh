#!/usr/bin/env zsh

alias yz='yazi'

yzc() {
  local cwd="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi --cwd-file="$cwd" "$@"
  # -s, not -f: a yazi killed mid-exit leaves the file empty, and cd'ing to ""
  # is cd'ing home.
  [[ -s $cwd ]] && [[ "$(<$cwd)" != "$PWD" ]] && builtin cd -- "$(<$cwd)"
  command rm -f -- "$cwd"
}
