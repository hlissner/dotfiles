# Based off Pure <https://github.com/sindresorhus/pure>

# For my own and others sanity
# git:
# %b => current branch
# %a => current action (rebase/merge)
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)

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
    # check if we're in a git repo
    [[ "$(command git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] || return
    # check if it's dirty
    [[ "$PURE_GIT_UNTRACKED_DIRTY" == 0 ]] && local umode="-uno" || local umode="-unormal"
    command test -n "$(git status --porcelain --ignore-submodules ${umode})"

    (($? == 0)) && echo '*'
}

# displays the exec time of the last command if set threshold was exceeded
prompt_cmd_exec_time() {
    local stop=$EPOCHSECONDS
    local start=${cmd_timestamp:-$stop}
    integer elapsed=$stop-$start
    (($elapsed > ${PURE_CMD_MAX_EXEC_TIME:=5})) && _human_time $elapsed
}


## Hooks ###############################
prompt_hook_preexec() {
    cmd_timestamp=$EPOCHSECONDS

    # shows the current dir and executed command in the title when a process is active
    print -Pn "\e]0;"
    echo -nE "$PWD:t: $2"
    print -Pn "\a"
}

prompt_hook_precmd() {
    # shows the full path in the title
    print -Pn '\e]0;%~\a'

    # git info
    vcs_info

    local prompt_preprompt="%F{blue}%~%F{242}$vcs_info_msg_0_`prompt_git_dirty`%f%F{yellow}`prompt_cmd_exec_time`%f"''
    # print -P $prompt_preprompt
    RPROMPT=$prompt_preprompt

    # check async if there is anything to pull
    (( ${PURE_GIT_PULL:-1} )) && {
        # check if we're in a git repo
        [[ "$(command git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] &&
        # make sure working tree is not $HOME
        [[ "$(command git rev-parse --show-toplevel)" != "$HOME" ]] &&
        # check check if there is anything to pull
        command git -c gc.auto=0 fetch &>/dev/null &&
        # check if there is an upstream configured for this branch
        command git rev-parse --abbrev-ref @'{u}' &>/dev/null && {
            local arrows=''
            (( $(command git rev-list --right-only --count HEAD...@'{u}' 2>/dev/null) > 0 )) && arrows='⇣'
            (( $(command git rev-list --left-only --count HEAD...@'{u}' 2>/dev/null) > 0 )) && arrows+='⇡'
            RPROMPT+="\e7\e[A\e[1G\e[`_string_length $prompt_preprompt`C%F{cyan}${arrows}%f\e8"
        }
    } &!

    # reset value since `preexec` isn't always triggered
    unset cmd_timestamp
}

prompt_hook_update_cursor() {
    # change cursor shape in iTerm2
    case $KEYMAP in
        vicmd)      print -n -- "\E]50;CursorShape=0\C-G";;  # block cursor
        viins|main) print -n -- "\E]50;CursorShape=1\C-G";;  # line cursor
    esac

    zle reset-prompt
    zle -R
}

prompt_hook_restore_cursor() {
    print -n -- "\E]50;CursorShape=0\C-G"  # block cursor
}

prompt_hook_update_vim_mode() {
  case $ZSH_CUR_KEYMAP in
    vicmd) CUR_MODE=$N_MODE ;;
    main|viins) CUR_MODE=$I_MODE ;;
  esac
  zle reset-prompt
}


## Initialization ######################
prompt_init() {
    # prevent percentage showing up
    # if output doesn't end with a newline
    export PROMPT_EOL_MARK=''
    # disable auth prompting on git 2.3+
    export GIT_TERMINAL_PROMPT=0

    prompt_opts=(cr subst percent)

    setopt PROMPTSUBST
    zmodload zsh/datetime
    autoload -Uz add-zsh-hook
    autoload -Uz vcs_info

    add-zsh-hook precmd prompt_hook_precmd
    add-zsh-hook preexec prompt_hook_preexec

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' use-simple true
    zstyle ':vcs_info:git*' formats ' %b'
    zstyle ':vcs_info:git*' actionformats ' %b|%a'

    ## Vim setup
    N_MODE="%F{blue}# "
    I_MODE="❯ "

    # Show $N-MODE if in normal mode
    hooks-add-hook zle_keymap_select_hook prompt_hook_update_vim_mode
    hooks-add-hook zle_line_init_hook prompt_hook_update_vim_mode

    # Change cursor depending on vim mode
    hooks-add-hook zle_line_init_hook prompt_hook_update_cursor
    hooks-add-hook zle_keymap_select_hook prompt_hook_update_cursor
    hooks-add-hook zle_line_finish_hook prompt_hook_restore_cursor


    # show username@host if logged in through SSH
    [[ "$SSH_CONNECTION" != '' ]] && prompt_username='%n@%m '

    # show username@host if root, with username in white
    [[ $UID -eq 0 ]] && prompt_username='%F{white}%n%F{242}@%m '

    # prompt turns red if the previous command didn't exit with 0
    PROMPT='$prompt_username%(?.%F{yellow}.%F{red})$CUR_MODE%f'
}

prompt_init "$@"
