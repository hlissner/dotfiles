#!/usr/bin/env sh

TMUX_VERSION=$(tmux -V | awk '{ print $2 }')

## Mouse #########
if (( $(echo "$TMUX_VERSION >= 2.1" | bc) )); then
    # setw -g mouse-utf8 on
    tmux setw -g mouse on
    # fix mouse scrolling: enter copy mode on scroll-up, exits it when scrolled to bottom
    tmux bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e'"
else
    tmux setw -g mode-mouse
    tmux set -g mouse-resize-pane on
    tmux set -g mouse-select-pane on
    tmux set -g mouse-select-window on
fi

# Fix clipboard access on osx
if [[ "$OSTYPE" == darwin* ]]; then
    tmux unbind p
    tmux bind p paste-buffer
    tmux bind-key -t vi-copy 'v' begin-selection
    tmux bind-key -t vi-copy 'y' copy-pipe "reattach-to-user-namespace pbcopy"

    tmux unbind -t vi-copy Enter
    tmux bind-key -t vi-copy Enter copy-pipe "reattach-to-user-namespace pbcopy"

    # Rather than constraining window size to the maximum size of any client
    # connected to the *session*, constrain window size to the maximum size of any
    # client connected to *that window*. Much more reasonable.
    tmux setw -g aggressive-resize off

    # increase scrollback buffer size
    tmux set -g history-limit 10000
else
    tmux setw -g aggressive-resize on

    # increase scrollback buffer size
    tmux set -g history-limit 5000
fi

# If in ssh, use default C-b prefix
if [[ -z "$SSH_CONNECTON" ]]
then
    # Remap the key prefix
    tmux set -g prefix ^c
    tmux unbind C-b
    # Restore sigterm C-c
    tmux bind C-c send-prefix

    tmux set -g status-bg colour237
    tmux set -g status-fg white
else
    tmux set -g status-bg yellow
    tmux set -g status-fg black
fi
