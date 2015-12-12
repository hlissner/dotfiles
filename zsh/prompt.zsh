# Based off Pure <https://github.com/sindresorhus/pure>

# turns seconds into human readable time
# 165392 => 1d 21h 56m 32s
_human_time() {
    echo -n " "
    local tmp=$1
    local days=$(( tmp / 60 / 60 / 24 ))
    local hours=$(( tmp / 60 / 60 % 24 ))
    local minutes=$(( tmp / 60 % 60 ))
    local seconds=$(( tmp % 60 ))
    (( $days > 0 )) && echo -n "${days}d "
    (( $hours > 0 )) && echo -n "${hours}h "
    (( $minutes > 0 )) && echo -n "${minutes}m "
    echo "${seconds}s"
}

# string length ignoring ansi escapes
_string_length() {
    # Subtract one since newline is counted as two characters
    echo $(( ${#${(S%%)1//(\%([KF1]|)\{*\}|\%[Bbkf])}} - 1 ))
}

# fastest possible way to check if repo is dirty
prompt_git_dirty() {
    # disable auth prompting on git 2.3+
    GIT_TERMINAL_PROMPT=0

    # check if we're in a git repo
    [[ "$(command git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] || return
    # check if it's dirty
    command test -n "$(git status --porcelain --ignore-submodules -unormal)" || return

    echo -n "%F{red}[+]"
    local r=$(command git rev-list --right-only --count HEAD...@'{u}' 2>/dev/null)
    local l=$(command git rev-list --left-only --count HEAD...@'{u}' 2>/dev/null)

    (( ${r:-0} > 0 )) && echo -n " %F{green}${r}⇣"
    (( ${l:-0} > 0 )) && echo -n " %F{yellow}${l}⇡"
    echo -n '%f'
}

# displays the exec time of the last command if set threshold was exceeded
prompt_cmd_exec_time() {
    local stop=$EPOCHSECONDS
    local start=${cmd_timestamp:-$stop}
    integer elapsed=$stop-$start
    (($elapsed > 2)) && _human_time $elapsed
}

## Hooks ###############################
prompt_hook_preexec() {
    cmd_timestamp=$EPOCHSECONDS
}

prompt_hook_precmd() {
    # shows the full path in the title
    print -Pn '\e]0;%~\a'
    # git info
    vcs_info
}

# Updates cursor shape and prompt symbol based on vim mode
prompt_hook_update_vim_mode() {
    case $KEYMAP in
        vicmd)      print -n -- "\E]50;CursorShape=0\C-G";
                    PROMPT_SYMBOL=$N_MODE;
                    ;;  # block cursor
        main|viins) print -n -- "\E]50;CursorShape=1\C-G";
                    PROMPT_SYMBOL=$I_MODE;
                    ;;  # line cursor
    esac
    zle reset-prompt
    zle -R
}
prompt_hook_restore_cursor() {
    print -n -- "\E]50;CursorShape=0\C-G"  # block cursor
}

## Initialization ######################
prompt_init() {
    # prevent percentage showing up
    # if output doesn't end with a newline
    export PROMPT_EOL_MARK=''

    prompt_opts=(cr subst percent)

    setopt PROMPTSUBST
    zmodload zsh/datetime
    autoload -Uz add-zsh-hook
    autoload -Uz vcs_info

    add-zsh-hook precmd prompt_hook_precmd
    add-zsh-hook preexec prompt_hook_preexec

    # Show $N-MODE if in normal mode and Change cursor depending on vim mode
    hooks-add-hook zle_keymap_select_hook prompt_hook_update_vim_mode
    hooks-add-hook zle_line_init_hook prompt_hook_update_vim_mode
    hooks-add-hook zle_line_finish_hook prompt_hook_restore_cursor

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' use-simple true
    zstyle ':vcs_info:*' max-exports 2
    zstyle ':vcs_info:git*' formats ':%b'
    zstyle ':vcs_info:git*' actionformats ':%b (%a)'

    # show username@host if logged in through SSH OR logged in as root
    [[ "$SSH_CONNECTION" != '' || "$UID" -eq 0 ]] && prompt_username='%F{white}%n%F{244}@%m '

    ## Vim cursors
    N_MODE="%F{blue}## "
    I_MODE=">> "

    RPROMPT='%F{blue}%~'                                     # PWD
    RPROMPT+='%F{242}${vcs_info_msg_0_}$(prompt_git_dirty)'  # Branch + dirty indicator
    RPROMPT+='%F{yellow}$(prompt_cmd_exec_time)'             # Exec time
    RPROMPT+='%f' # end

    PROMPT='$prompt_username'                         # username
    PROMPT+='%(?.%F{yellow}.%F{red})${PROMPT_SYMBOL}' # Prompt (red if $? == 0)
    PROMPT+='%f' #end
}

prompt_init "$@"
