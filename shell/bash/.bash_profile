
_init_path() {
    shopt -s nullglob
    paths=( ~/.local/bin $DOTFILES/bin $DOTFILES_CACHE/*.topic/bin )
    export PATH="$(printf '%s:' "${paths[@]}"):$PATH"
}
_init_path
