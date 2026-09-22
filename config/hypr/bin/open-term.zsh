#!/usr/bin/env zsh
# Open a foot terminal.
#
# SYNOPSIS:
#   open-term [-t TITLE] [-f FONT] [-F N] [-o OPT]... [FOOTARGS...] [-- TMUXARGS...]
#
# DESCRIPTION:
#   Arguments before a literal -- are passed to foot; those after it are passed
#   to tmux. With a TITLE, the terminal is named and attached to a tmux session
#   of the same name.
#
# OPTIONS:
#   -o OPT
#     Pass an option to foot (-o key=value). May be repeated.
#   -t, --title TITLE
#     Name the terminal, and attach it to a tmux session of that name.
#   -f, --font FONT
#     Use FONT instead of the configured one.
#   -F, --font-adjust N
#     Adjust the font size by N points.

zparseopts -E -D -F -- o+:=opts \
                       {t,-title}:=title \
                       {f,-font}:=font \
                       {F,-font-adjust}:=font_offset || exit 1

local offset=$(( ${font_offset[2]:-0} ))
local idx=${@[(i)(--)]}
local -a footopts=( ${@[1,$idx-1]} )
local -a tmuxopts=( ${@[$idx+1,-1]} )

if [[ $title ]]; then
  footopts=( -T "${title[2]}" ${footopts[@]} )
  tmuxopts=( new -A -s "${title[2]}" ${tmuxopts[@]} )
elif (( ${#tmuxopts} )); then
  tmuxopts=( -c "${tmuxopts[@]}" )
fi

if [[ -z "$font" ]]; then
  font=( -f "$(hey info theme fonts terminal | jq -r '. | "\(.name):size=\(.size)"')" )
fi

fontname="${font[2]%%:*}"
fontsize="${${font[2]//*:*size=}%%:*}"
fontsize="${fontsize:-9}"
footopts+=( -o "main.font=${fontname:-JetBrainsMono Nerd Font}:size=$fontsize" ${opts[@]} )

hey.do foot "${footopts[@]}" -- tmux ${tmuxopts[@]}
