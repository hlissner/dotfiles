#!/usr/bin/env zsh
# zshrc
# By Henrik Lissner <henrik@lissner.net>

repo "tarjoilija/zgen" "$HOME/.zgen"

source "$HOME/.zgen/zgen.zsh"
if ! zgen saved; then
    info "Creating zgen save"

    cache-clear

    zgen load hlissner/zsh-autopair "autopair.zsh"
    zgen load zsh-users/zsh-history-substring-search
    zgen load zsh-users/zsh-completions src

    [[ $SSH_CONNECTION ]] || zgen load zsh-users/zsh-syntax-highlighting

    zgen save
fi

if is-interactive; then
    load shell/+zsh/completion.zsh
    load shell/+zsh/keybinds.zsh
    load shell/+zsh/prompt.zsh

    cache fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install
fi
loadall aliases.zsh

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Done!
