#!/usr/bin/env zsh

alias ta='tmux attach'
alias tl='tmux ls'

if [[ -n $TMUX ]]; then # From inside tmux
  alias tf='tmux find-window'
  # Detach all other clients to this session
  alias mine='tmux detach -a'
  # Send command to other tmux window
  tt() {
    tmux send-keys -t .+ C-u && \
      tmux set-buffer "$*" && \
      tmux paste-buffer -t .+ && \
      tmux send-keys -t .+ Enter;
  }
  # Create new session (from inside one)
  tn() {
    local name="${1:-`basename $PWD`}"
    TMUX= tmux new-session -d -s "$name"
    tmux switch-client -t "$name"
    tmux display-message "Session #S created"
  }
else # From outside tmux
  # Start grouped session so I can be in two different windows in one session
  tdup() { tmux new-session -t "${1:-`tmux display-message -p '#S'`}"; }
fi
