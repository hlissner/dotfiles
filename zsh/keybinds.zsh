bindkey -v

# Allow command line editing in an external editor.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^ ' edit-command-line

# zsh-autopair
bindkey '`'  autopair-insert
bindkey '"'  autopair-insert
bindkey "'"  autopair-insert
bindkey '('  autopair-insert
bindkey '['  autopair-insert
bindkey '{'  autopair-insert
bindkey '^?' autopair-delete # smart backspace

bindkey '^n' history-substring-search-down
bindkey '^p' history-substring-search-up
bindkey '^s' history-incremental-pattern-search-backward
bindkey '^u' undo
bindkey '^r' redo
bindkey '^w' backward-kill-word
bindkey '^b' backward-word
bindkey '^e' forward-word
bindkey '^q' push-line-or-edit
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

# Shift + Tab
bindkey -M viins '^[[Z'  reverse-menu-complete

bindkey -M viins ' '     magic-space
bindkey -M viins 'jk'    vi-cmd-mode

# Vim keymaps
bindkey -M vicmd 'ga'    what-cursor-position
bindkey -M vicmd 'gg'    beginning-of-history
bindkey -M vicmd 'G '    end-of-history
bindkey -M vicmd '^k'    kill-line
bindkey -M vicmd '?'     history-incremental-pattern-search-forward
bindkey -M vicmd '/'     history-incremental-pattern-search-backward
bindkey -M vicmd ':'     execute-named-cmd
# Page up / Page down
bindkey -M vicmd 'H'     run-help
bindkey -M vicmd 'u'     undo
bindkey -M vicmd 'U'     redo
bindkey -M vicmd 'yy'    vi-yank-whole-line
bindkey -M vicmd 'Y'     vi-yank-eol

# bind UP and DOWN arrow keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Completion
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
export KEYTIMEOUT=10   # just enough time for jk
bindkey -sM vicmd '^[' '^G'
bindkey -rM viins '^X'
bindkey -M viins '^X,' _history-complete-newer \
                 '^X/' _history-complete-older \
                 '^X`' _bash_complete-word
