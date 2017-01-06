# Loaded at the end of the initialization process

export PATH="$HOME/.bin:$DOTFILES/bin:$PATH"

#
export EDITOR=$(is-callable nvim && echo 'nvim' || echo 'vim')
export VISUAL=$EDITOR

#
export GPG_TTY=$(tty)
