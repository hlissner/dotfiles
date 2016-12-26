
if [[ $OSTYPE == darwin* ]]; then
    alias mpdi='mpd ~/.config/mpd/mpd.conf'
fi

alias mpc='mpc -h "$HOME/.config/mpd/mpd.sock"'

mpca() {
    local files=()
    for file in $@; do
        files+="$(realpath --relative-to="$HOME/music" "$file")"
    done
    mpc add ${files[@]}
}
