#!/usr/bin/env zsh
# zshrc
# By Henrik Lissner <henrik@lissner.net>

if is-interactive; then
    AUTOPAIR_INHIBIT_INIT=1

    repo "tarjoilija/zgen" "$HOME/.zgen"
    source "$HOME/.zgen/zgen.zsh"
    if ! zgen saved; then
        info "Creating zgen save"

        cache-clear

        zgen load hlissner/zsh-autopair
        zgen load zsh-users/zsh-history-substring-search
        zgen load zdharma/history-search-multi-word
        zgen load zsh-users/zsh-completions src

        if [[ -z $SSH_CONNECTION ]]; then
            zgen load zdharma/fast-syntax-highlighting
        fi

        zgen save
    fi

    load shell/+zsh/completion.zsh
    load shell/+zsh/keybinds.zsh
    load shell/+zsh/prompt.zsh

    cache fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install
    autopair-init
fi
loadall aliases.zsh

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Done!
