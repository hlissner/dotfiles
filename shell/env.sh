# Loaded at the end of the initialization process

export PATH="$DOTFILES/bin:$HOME/bin:$PATH"

#
export EDITOR=$(is-callable nvim && echo 'nvim' || echo 'vim')
export VISUAL=$EDITOR

#
export GPG_TTY=$(tty)
umask 077
