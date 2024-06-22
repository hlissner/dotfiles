#!/usr/bin/env zsh

# Stop TRAMP (in Emacs) from hanging or term/shell from echoing back commands
if [[ $TERM == dumb || -n $INSIDE_EMACS ]]; then
  unsetopt zle prompt_cr prompt_subst
  whence -w precmd >/dev/null && unfunction precmd
  whence -w preexec >/dev/null && unfunction preexec
  PS1='$ '
fi

## Bootstrap interactive session
if [[ $TERM != dumb ]]; then
  # Don't call compinit too early. I'll do it myself, at the right time.
  export ZGEN_AUTOLOAD_COMPINIT=0

  ## ZSH configuration
  if (( $+commands[bat] )); then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT='-c'
  fi

  # Treat these characters as part of a word.
  WORDCHARS='-*?[]~&.;!#$%^(){}<>'
  unsetopt BRACE_CCL        # Allow brace character class list expansion.
  setopt COMBINING_CHARS    # Combine zero-length punc chars (accents) with base char
  setopt RC_QUOTES          # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
  setopt HASH_LIST_ALL
  unsetopt CORRECT_ALL
  unsetopt NOMATCH
  unsetopt MAIL_WARNING     # Don't print a warning message if a mail file has been accessed.
  unsetopt BEEP             # Hush now, quiet now.
  setopt IGNOREEOF
  ## Jobs
  setopt LONG_LIST_JOBS     # List jobs in the long format by default.
  setopt AUTO_RESUME        # Attempt to resume existing job before creating a new process.
  setopt NOTIFY             # Report status of background jobs immediately.
  unsetopt BG_NICE          # Don't run all background jobs at a lower priority.
  unsetopt HUP              # Don't kill jobs on shell exit.
  unsetopt CHECK_JOBS       # Don't report on jobs when shell exit.
  ## History
  HISTORY_SUBSTRING_SEARCH_PREFIXED=1
  HISTORY_SUBSTRING_SEARCH_FUZZY=1
  HISTSIZE=100000   # Max events to store in internal history.
  SAVEHIST=100000   # Max events to store in history file.
  setopt BANG_HIST                 # History expansions on '!'
  setopt EXTENDED_HISTORY          # Include start time in history records
  setopt APPEND_HISTORY            # Appends history to history file on exit
  setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
  setopt SHARE_HISTORY             # Share history between all sessions.
  setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
  setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
  setopt HIST_IGNORE_ALL_DUPS      # Remove old events if new event is a duplicate
  setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
  setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
  setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
  setopt HIST_REDUCE_BLANKS        # Minimize unnecessary whitespace
  setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
  setopt HIST_BEEP                 # Beep when accessing non-existent history.
  ## Directories
  DIRSTACKSIZE=9
  unsetopt AUTO_CD            # Implicit CD slows down plugins
  setopt AUTO_PUSHD           # Push the old directory onto the stack on cd.
  setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
  setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.
  unsetopt PUSHD_TO_HOME      # Don't push to $HOME when no argument is given.
  setopt CDABLE_VARS          # Change directory to a path stored in a variable.
  setopt MULTIOS              # Write to multiple descriptors.
  unsetopt GLOB_DOTS
  unsetopt AUTO_NAME_DIRS     # Don't add variable-stored paths to ~ list

  ## Plugin configuration
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_OPTS="--reverse --ansi"
    export FZF_DEFAULT_COMMAND="fd ."
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd -t d . $HOME"
  fi
  # zsh-vi-mode
  export ZVM_INIT_MODE=sourcing
  export ZVM_VI_ESCAPE_BINDKEY=^G
  export ZVM_LINE_INIT_MODE=i
  # zsh-autosuggest
  export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

  ## Bootstrap zgenom
  export ZGEN_DIR="${ZGEN_DIR:-${XDG_DATA_HOME:-~/.local/share}/zgenom}"
  if [[ ! -d "$ZGEN_DIR" ]]; then
    # Use zgenom because zgen is no longer maintained
    echo "Installing jandamm/zgenom"
    git clone https://github.com/jandamm/zgenom "$ZGEN_DIR"
  fi

  source $ZGEN_DIR/zgenom.zsh
  zgenom autoupdate   # checks for updates every ~7 days
  if ! zgenom saved; then
    echo "Initializing zgenom"
    rm -frv $ZDOTDIR/*.zwc(N) \
            $ZDOTDIR/.*.zwc(N) \
            $XDG_CACHE_HOME/zsh \
            $ZGEN_INIT.zwc

    # Be extra careful about plugin load order, or subtle breakage can emerge.
    # This is the best order I've sussed out for these plugins.
    zgenom load junegunn/fzf shell
    zgenom load jeffreytse/zsh-vi-mode
    zgenom load zdharma-continuum/fast-syntax-highlighting
    zgenom load zsh-users/zsh-completions src
    zgenom load zsh-users/zsh-autosuggestions
    zgenom load dxrcy/zsh-history-substring-search
    zgenom load romkatv/powerlevel10k powerlevel10k
    zgenom load hlissner/zsh-autopair autopair.zsh

    zgenom save

    # Must be explicit because zgenom compile ignores nix-store symlinks
    zgenom compile \
      $ZDOTDIR/*(-.N) \
      $ZDOTDIR/.*(-.N) \
      $ZDOTDIR/completions/_*(-.N) \
      $DOTFILES_HOME/lib/zsh/*~*.zwc(.N)
  fi

  ## My dotfiles
  source $ZDOTDIR/completion.zsh
  source $ZDOTDIR/keybinds.zsh
  source $ZDOTDIR/aliases.zsh
  source $ZDOTDIR/extra.zshrc   # Auto-generated by nixos

  autopair-init

  # CD-able vars
  cfg=~/.config
fi
