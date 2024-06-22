#!/usr/bin/env zsh
# Open a foot terminal.
#
# SYNOPSIS:
#   open-term [TITLE] [COMMAND] [ARGS...]
#
# DESCRIPTION:
#   Opens a foot terminal with a new Tmux session. If opened from a special
#   (Hypr) workspace, a larger font and lower opacity is used.

zparseopts -E -D -F -- o+:=opts \
                       {t,-title}:=title \
                       {f,-font}:=font \
                       {F,-font-adjust}:=font_offset || exit 1

local offset=$(( ${font_offset[2]:-0} ))
local idx=${@[(i)(--)]}
local -a footopts=( ${@[1,$idx-1]} )
local -a tmuxopts=( ${@[$idx+1,-1]} )

if [[ "$(hey .get-activeworkspace .name)" == special:* ]]; then
  offset=$(( offset + 3 ))
fi

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
footopts+=( -o "main.font=${fontname}:size=$(( fontsize + offset ))" ${opts[@]} )

hey.do foot "${footopts[@]}" -- tmux ${tmuxopts[@]}
