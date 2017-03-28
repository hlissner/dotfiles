# Loaded at the end of the initialization process

export EDITOR=$(is-callable nvim && echo 'nvim' || echo 'vim')
export VISUAL=$EDITOR
export GPG_TTY=$(tty)

[[ $LANG ]] || export LANG='en_US.UTF-8'
export TERMINFO="$HOME/.terminfo"
