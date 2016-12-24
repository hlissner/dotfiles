source "$HOME/.dotfiles/shell/common.sh"

## Paths
# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path
path=( /usr/local/{,s}bin $path )

load shell/zsh/config.zsh
loadall env.zsh

path=( $HOME/.bin $DOTFILES/bin $path )

fpath=(
    $DOTFILES/shell/zsh/{completions,functions}
    $fpath
)

export LESS='-g -i -M -R -S -w -z-4'
if is-callable lesspipe; then
    export LESSOPEN='| /usr/bin/env lesspipe %s 2>&-'
fi

[[ $LANG ]] || export LANG='en_US.UTF-8'
