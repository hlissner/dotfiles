#!/usr/bin/env zsh
# Loosely based off Pure <https://github.com/sindresorhus/pure>

_strlen() { echo ${#${(S%%)1//$~%([BSUbfksu]|([FB]|){*})/}}; }

# fastest possible way to check if repo is dirty
prompt_git_dirty() {
    is-callable git || return

    # check if we're in a git repo
    [[ "$(command git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] || return
    # check if it's dirty
    command test -n "$(git status --porcelain --ignore-submodules -unormal)" || return

    local r=$(command git rev-list --right-only --count HEAD...@'{u}' 2>/dev/null)
    local l=$(command git rev-list --left-only --count HEAD...@'{u}' 2>/dev/null)

    (( ${r:-0} > 0 )) && echo -n " %F{green}${r}-"
    (( ${l:-0} > 0 )) && echo -n " %F{yellow}${l}+"
    echo -n '%f'
}

## Hooks ###############################
prompt_hook_precmd() {
    vcs_info # get git info
    # Newline before prompt, except on init
    [[ $PROMPT_DONE ]] && print ""; PROMPT_DONE=1
}

## Initialization ######################
prompt_init() {
    # prevent the extra space in the rprompt
    [[ $EMACS ]] || ZLE_RPROMPT_INDENT=0
    # prevent percentage showing up
    # if output doesn't end with a newline
    export PROMPT_EOL_MARK=

    # prompt_opts=(cr subst percent)
    setopt PROMPTSUBST
    autoload -Uz add-zsh-hook
    autoload -Uz vcs_info

    add-zsh-hook precmd prompt_hook_precmd
    # Updates cursor shape and prompt symbol based on vim mode
    zle-keymap-select() {
        case $KEYMAP in
            vicmd)      PROMPT_SYMBOL="%F{magenta}## " ;;
            main|viins) PROMPT_SYMBOL="%(?.%F{cyan}.%F{red})λ " ;;
        esac
        zle reset-prompt
        zle -R
    }
    zle -N zle-keymap-select
    zle -A zle-keymap-select zle-line-init

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' use-simple true
    zstyle ':vcs_info:*' max-exports 2
    zstyle ':vcs_info:git*' formats '%b'
    zstyle ':vcs_info:git*' actionformats '%b (%a)'

    # show username@host if logged in through SSH
    [[ $SSH_CONNECTION ]] && prompt_username='%F{magenta}%n%F{244}@%m '

    RPROMPT=' %F{magenta}${vcs_info_msg_0_}$(prompt_git_dirty)%f'
    PROMPT='%F{blue}%~ ${prompt_username}${PROMPT_SYMBOL:-$ }'
}

prompt_init "$@"
