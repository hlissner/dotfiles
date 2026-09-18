#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload
#
# SYNOPSIS:
#   Triggered by 'hey reload'

echo "Deleting zsh cache files..."
rm -frv "$XDG_CACHE_HOME"/zsh/*(DN)

echo "Deleting compiled zsh files..."
rm -fv "$ZDOTDIR"/**/*.zwc(D.N)
rm -fv "${DOTFILES_HOME:-$HOME/.config/dotfiles}"/config/zsh/**/*.zwc(D.N)

# Can't use `zpm clean` because these hooks can run outside an interactive shell
# where zpm's functions aren't loaded.
echo "Resetting zpm..."
rm -frv "${ZSH_TMP_DIR:-${TMPDIR:-/tmp}/zsh-${UID:-user}}"
