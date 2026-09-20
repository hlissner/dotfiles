#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload
#
# DESCRIPTION:
#   Deletes zpm's init file, ZSH's cache, and all compiled zsh scripts. Next
#   time you start up a zsh shell it'll rebuild all it needs.

echo "zsh: deleting zsh cache files..."
rm -fr "$XDG_CACHE_HOME"/zsh/*(DN)

echo "zsh: deleting compiled zsh files..."
rm -f "$ZDOTDIR"/**/*.zwc(D.N)
rm -f "${DOTFILES_HOME:-$HOME/.config/dotfiles}"/config/zsh/**/*.zwc(D.N)

# Can't use `zpm clean` because these hooks can run outside an interactive shell
# where zpm's functions aren't loaded.
echo "zsh: resetting zpm..."
rm -fr "${ZSH_TMP_DIR:-${TMPDIR:-/tmp}/zsh-${UID:-user}}"
