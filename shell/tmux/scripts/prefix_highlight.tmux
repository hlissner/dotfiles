#!/usr/bin/env bash

set -e

# Place holder for status left/right
place_holder="\#{prefix_highlight}"

# Possible configurations
fg_color_config='@prefix_highlight_fg'
bg_color_config='@prefix_highlight_bg'

# Defaults
default_fg='black'
default_bg='yellow'

tmux_option() {
    local -r value=$(tmux show-option -gqv "$1")
    local -r default="$2"

    if [ ! -z "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

highlight() {
    local -r status="$1" prefix="$2" fg_color="$3" bg_color="$4"
    local -r status_value=$(tmux_option "$status")
    local -r highlight_on_prefix="#[fg=$fg_color,bg=$bg_color]#{?client_prefix, $prefix ,}#[fg=default,bg=default]"

    tmux set-option -gq "$status" "${status_value/$place_holder/$highlight_on_prefix}"
}

main() {
    local -r \
        prefix=$(tmux_option prefix) \
        fg_color=$(tmux_option "$fg_color_config" "$default_fg") \
        bg_color=$(tmux_option "$bg_color_config" "$default_bg")

    local -r short_prefix=$(
        echo "$prefix" | tr "[:lower:]" "[:upper:]" | sed 's/C-/\^/'
    )

    highlight "status-right" "$short_prefix" "$fg_color" "$bg_color"
    highlight "status-left" "$short_prefix" "$fg_color" "$bg_color"
}

main
