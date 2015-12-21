
# Clean up symlinks in fasd
if is-callable 'fasd'; then
    for entry in $(fasd -l); do
        if [[ -L "$entry" ]]; then
            local realpath=$(realpath "$entry")
            fasd -D "$entry"
            fasd -A "$realpath"
        fi
    done
fi

