bindkey -v
bindkey '^ ' edit-command-line

bindkey -M viins '^w' backward-kill-word
bindkey -M viins '^[w' forward-word
bindkey -M viins '^[b' backward-word

bindkey -M vicmd 'yy' vi-yank-whole-line
bindkey -M vicmd 'Y' vi-yank-eol

bindkey -M viins ' ' magic-space
bindkey -M viins 'jk' vi-cmd-mode

bindkey -M viins '^x^f' fasd-complete-f  # C-x C-f to do fasd-complete-f (only files)
bindkey -M viins '^x^d' fasd-complete-d  # C-x C-d to do fasd-complete-d (only directories)

bindkey -M viins '^q' push-line-or-edit

bindkey -M vicmd "?" history-incremental-pattern-search-backward
bindkey -M vicmd "/" history-incremental-pattern-search-forward

# bind UP and DOWN arrow keys
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
# bind UP and DOWN arrow keys (compatibility fallback
# for Ubuntu 12.04, Fedora 21, and MacOSX 10.9 users)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down]]]]

# Edit command in an external editor.
bindkey -M vicmd "R" edit-command-line

# # Undo/Redo
bindkey -M vicmd "u" undo
bindkey -M vicmd "$key_info[Control]R" redo

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

    bindkey -M viins '^n' tmux-pane-words-prefix
    bindkey -M viins '^o' tmux-pane-words-anywhere

    zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' completer _tmux_pane_words
    zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' ignore-line current
    zstyle ':completion:tmux-pane-words-anywhere:*' matcher-list 'b:=* m:{A-Za-z}={a-zA-Z}'
fi
