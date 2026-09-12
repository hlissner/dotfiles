#!/usr/bin/env zsh

alias -s pdf='$BROWSER'
alias -s {jpg,jpeg,gif,png,svg}=swayimg

alias dr='ripdrag'
alias y='wl-copy'
alias p='wl-paste'

(( $+commands[mpv] )) && alias -s {mp4,avi,mkv,mov}='mpv --loop'
(( $+commands[xdg-open] )) && alias open=xdg-open
(( $+commands[img2sixel] )) && alias six=img2sixel

alias reload='source /run/current-system/etc/set-environment'
