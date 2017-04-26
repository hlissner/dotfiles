if is-interactive; then
    path=($HOME/.tmuxifier $path)
    export TMUXIFIER="$DOTFILES/shell/+tmux/.tmuxifier"
    export TMUXIFIER_LAYOUT_PATH="$DOTFILES/shell/+tmux/.tmux/layouts"
    cache tmuxifier init -
fi
