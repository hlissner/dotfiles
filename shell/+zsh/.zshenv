## Paths
source "$HOME/.dotfiles/shell/common.sh"

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path
path=( $DOTFILES/bin "$ENABLED_DIR"/*/bin /usr/local/{,s}bin $path )

load shell/+zsh/config.zsh
loadall env.zsh

path=( $HOME/bin $path )

fpath=(
    $DOTFILES/shell/+zsh/completions
    $fpath
)

export LESS='-g -i -M -R -S -w -z-4'
export SHELL=$(which zsh)
if is-callable lesspipe; then
    export LESSOPEN='| /usr/bin/env lesspipe %s 2>&-'
fi
