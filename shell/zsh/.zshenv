export DOTFILES="$HOME/.dotfiles"

source "$DOTFILES/shell/common.sh"

## Paths
# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

path=(
    $DOTFILES/bin
    $HOME/bin
    /usr/local/{,s}bin
    $path
)

fpath=(
    $DOTFILES/shell/zsh/{completions,functions}
    $fpath
)

export EDITOR=$(is-callable nvim && echo 'nvim' || echo 'vim')
export VISUAL=$EDITOR
export LESS='-g -i -M -R -S -w -z-4'
if is-callable lesspipe; then
    export LESSOPEN='| /usr/bin/env lesspipe %s 2>&-'
fi

[[ -z "$LANG" ]] && export LANG='en_US.UTF-8'
