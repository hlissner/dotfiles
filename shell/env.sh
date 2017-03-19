# Loaded at the end of the initialization process

#
export EDITOR=$(is-callable nvim && echo 'nvim' || echo 'vim')
export VISUAL=$EDITOR

#
export GPG_TTY=$(tty)

PATH="$DOTFILES/bin:$PATH"
bins=( "$ENABLED_DIR"/*/bin )
for bin in "${bins[@]}"; do
    [[ -e "$bin" ]] && PATH="$bin:$PATH"
done
export PATH
