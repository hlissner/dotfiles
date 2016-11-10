if is-interactive; then
    path=($HOME/.tmuxifier $path)
    export TMUXIFIER_LAYOUT_PATH="$HOME/.tmux/layouts"
    cache tmuxifier init -
fi
