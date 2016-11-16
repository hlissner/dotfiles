# Ran into an issue where the surround module wasn't working if KEYTIMEOUT is <= 10.
# Specifically, (delete|change)-surround immediately abort into insert mode if
# KEYTIMEOUT <= 8, and if <= 10, then add-surround would do the same. At 11, all these
# issues vanish. Very strange!
export KEYTIMEOUT=15

autoload -U is-at-least

## vi-mode ###############
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
# bindkey -M viins '^I' expand-or-complete-prefix

# surround
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -a cs change-surround
bindkey -a ds delete-surround
bindkey -a ys add-surround
bindkey -M visual S add-surround

# text-objects
if is-at-least 5.0.8; then
    autoload -U select-quoted; zle -N select-quoted
    for m in visual viopp; do
        for c in {a,i}{\',\",\`}; do
            bindkey -M $m $c select-quoted
        done
    done
    autoload -U select-bracketed; zle -N select-bracketed
    for m in visual viopp; do
        for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
            bindkey -M $m $c select-bracketed
        done
    done
fi

# Allow command line editing in an external editor.
autoload -Uz edit-command-line; zle -N edit-command-line
bindkey '^ ' edit-command-line

bindkey -M viins '^n' history-substring-search-down
bindkey -M viins '^p' history-substring-search-up
bindkey -M viins '^s' history-incremental-pattern-search-backward
bindkey -M viins '^u' backward-kill-line
bindkey -M viins '^w' backward-kill-word
bindkey -M viins '^b' backward-word
bindkey -M viins '^f' forward-word
bindkey -M viins '^g' push-line-or-edit
bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line
bindkey -M viins '^d' push-line-or-edit

bindkey -M viins ' '  magic-space
bindkey -M vicmd '^k' kill-line
bindkey -M vicmd 'H'  run-help

# Shift + Tab
bindkey -M viins '^[[Z'  reverse-menu-complete

# bind UP and DOWN arrow keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# C-z to background *and* foreground processes
fancy-ctrl-z () {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fg"
    zle accept-line
  else
    zle push-input
    zle clear-screen
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# Omni-Completion
bindkey -M viins '^x^f' fasd-complete-f  # C-x C-f to do fasd-complete-f (only files)
bindkey -M viins '^x^d' fasd-complete-d  # C-x C-d to do fasd-complete-d (only directories)
# Completing words in buffer in tmux
if [ -n "$TMUX" ]; then
    _tmux_pane_words() {
        local expl
        local -a w
        if [[ -z "$TMUX_PANE" ]]; then
            _message "not running inside tmux!"
            return 1
        fi
        w=( ${(u)=$(tmux capture-pane \; show-buffer \; delete-buffer)} )
        _wanted values expl 'words from current tmux pane' compadd -a w
    }

    zle -C tmux-pane-words-prefix   complete-word _generic
    zle -C tmux-pane-words-anywhere complete-word _generic

    bindkey -M viins '^x^n' tmux-pane-words-prefix
    bindkey -M viins '^x^o' tmux-pane-words-anywhere

    zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' completer _tmux_pane_words
    zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' ignore-line current
    zstyle ':completion:tmux-pane-words-anywhere:*' matcher-list 'b:=* m:{A-Za-z}={a-zA-Z}'
fi

# Vim's C-x C-l in zsh
history-beginning-search-backward-then-append() {
  zle history-beginning-search-backward
  zle vi-add-eol
}
zle -N history-beginning-search-backward-then-append
bindkey -M viins '^x^l' history-beginning-search-backward-then-append

# Fixes
bindkey -M vicmd "^[[3~" delete-char
bindkey "^[[3~"   delete-char
bindkey "^[3;5~"  delete-char

# Fix vimmish ESC
bindkey -sM vicmd '^[' '^G'
bindkey -rM viins '^X'
bindkey -M viins '^X,' _history-complete-newer \
                 '^X/' _history-complete-older \
                 '^X`' _bash_complete-word

# In-place search insertion
autoload -Uz narrow-to-region
function _history-incremental-preserving-pattern-search-backward
{
  local state
  MARK=CURSOR  # magick, else multiple ^R don't work
  narrow-to-region -p "$LBUFFER${BUFFER:+>>}" -P "${BUFFER:+<<}$RBUFFER" -S state
  zle end-of-history
  zle history-incremental-pattern-search-backward
  narrow-to-region -R state
}
zle -N _history-incremental-preserving-pattern-search-backward
bindkey "^R" _history-incremental-preserving-pattern-search-backward
bindkey -M isearch "^R" history-incremental-pattern-search-backward
bindkey "^S" history-incremental-pattern-search-forward
