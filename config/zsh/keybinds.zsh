# Much of this depends on jeffreytse/zsh-vi-mode and ZVM_INIT_MODE=sourcing.

# bindkey -M viins '^a' beginning-of-line  # already set by zvm
bindkey -M viins '^d' push-line-or-edit

# Vanilla behavior is to move by characters
bindkey -M viins '^b' backward-word
bindkey -M viins '^f' forward-word

# Up arrow:
bindkey -M viins '\e[A' history-substring-search-up
bindkey -M viins '\eOA' history-substring-search-up
# Down arrow:
bindkey -M viins '\e[B' history-substring-search-down
bindkey -M viins '\eOB' history-substring-search-down

# C-z to toggle current process (background/foreground)
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

if (( $+commands[fzf] )); then
  bindkey '^R' fzf-history-widget   # take back ^R from zvm
fi

# Omni-Completion
if (( $+commands[zoxide] )); then
  # C-x C-d: pick a directory from zoxide db
  zoxide-complete-d() {
    local query dir
    query=${LBUFFER##* }
    dir=$(zoxide query --interactive -- "$query") || { zle redisplay; return 0 }
    LBUFFER=${LBUFFER%"$query"}${(q-)dir}
    zle reset-prompt
  }
  zle -N zoxide-complete-d

  # C-x C-f: pick a directory from zoxide db, then a file inside it
  zoxide-complete-f() {
    local query dir file full
    query=${LBUFFER##* }
    dir=$(zoxide query --interactive -- "$query") || { zle redisplay; return 0 }
    file=$(cd -- "$dir" && fd --type f --hidden --exclude .git |
               fzf --height 40% --reverse --prompt='file> ') || { zle redisplay; return 0 }
    full=$dir/$file
    LBUFFER=${LBUFFER%"$query"}${(q-)full}
    zle reset-prompt
  }
  zle -N zoxide-complete-f

  bindkey -M viins '^x^d' zoxide-complete-d
  bindkey -M viins '^x^f' zoxide-complete-f
fi

# Completing words on screen in tmux, ala vim's ^X^N/^X^O
if [[ -n "$TMUX" ]]; then
  # How much scrollback to mine per pane
  : ${TMUX_PANE_WORDS_LINES:=2000}

  _tmux_pane_words() {
    local expl pane
    local -a w
    for pane in ${(f)"$(tmux list-panes -F '#{pane_id}' 2>/dev/null)"}; do
      w+=( ${=$(tmux capture-pane -p -S -$TMUX_PANE_WORDS_LINES -t $pane 2>/dev/null)} )
    done
    (( $#w )) || return 1
    # Dedupe in place: compadd -a takes the name of an array, not its values
    w=( ${(u)w} )
    _wanted values expl 'words from tmux panes' compadd -a w
  }

  zle -C tmux-pane-words-prefix   complete-word _generic
  zle -C tmux-pane-words-anywhere complete-word _generic

  bindkey -M viins '^x^n' tmux-pane-words-prefix
  bindkey -M viins '^x^o' tmux-pane-words-anywhere

  zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' completer _tmux_pane_words
  zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' ignore-line current
  zstyle ':completion:tmux-pane-words-anywhere:*' matcher-list 'b:=* m:{A-Za-z}={a-zA-Z}'
fi

# ^X^V ala vim's command-line completion: every command on $PATH, plus builtins,
# functions and aliases, regardless of cursor position.
zle -C complete-commands complete-word _command_names
bindkey -M viins '^x^v' complete-commands

# ^X^K ala vim's dictionary completion, but powered by aspell. First press
# offers aspell's suggestions for word at point. Pressed twice and it invokes
# fzf on the English dictionary. A word aspell is happy with has no suggestions,
# so skip to fzf+dictionary in that case.
#
# ^Xc (_correct_word) already handles the in-place single-guess case; this is
# for when you want to see the options.
if (( $+commands[aspell] && $+commands[fzf] )); then
  spell-complete() {
    local word=${LBUFFER##*[[:space:]]}
    local -a suggestions
    local pick

    if [[ $LASTWIDGET != $WIDGET ]]; then
      # `aspell -a` answers "& word N offset: a, b, c" for a misspelling and "*"
      # for one it knows. Skip its version banner on line 1.
      suggestions=( ${(f)"$(print -r -- $word | aspell -a 2>/dev/null |
        awk 'NR > 1 && /^&/ { sub(/^[^:]*: /, ""); gsub(/, /, "\n"); print }')"} )
    fi

    if (( $#suggestions )); then
      pick=$(print -rl -- $suggestions |
               fzf --height 40% --reverse --prompt='spell> ')
    else
      pick=$(aspell dump master 2>/dev/null |
               fzf --height 40% --reverse --prompt='dict> ' --query="$word")
    fi

    [[ -n $pick ]] || { zle redisplay; return 0 }
    LBUFFER=${LBUFFER%"$word"}$pick
    zle reset-prompt
  }
  zle -N spell-complete
  bindkey -M viins '^x^k' spell-complete
fi

# Vim's C-x C-l in zsh
history-beginning-search-backward-then-append() {
  zle history-beginning-search-backward
  zle vi-add-eol
}
zle -N history-beginning-search-backward-then-append
bindkey -M viins '^x^l' history-beginning-search-backward-then-append
