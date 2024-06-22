#!/usr/bin/env zsh
# Return the primary terminal font.
#
# SYNOPSIS:
#   get-font [--xft|-c|-s|-n]
#
# DESCRIPTION:
#   TODO

local font="$(hey info theme fonts terminal | jq -r '. | "\(.name);\(.size)"')"
local fontname="${font/;*/}"
local fontsize="${font/*;/}"

zparseopts -E -D -F -- {c,n,s,-xft}=opts || exit 1
if [[ -z $opts ]]; then
  echo "${fontname}:size=${fontsize}"
else
  case ${opts[1]} in
    *--xft*) echo "$fontname-$fontsize" ;;
    *-c*) echo "$fontname,$fontsize" ;;
    *-n*) echo $fontname ;;
    *-s*) echo $fontsize ;;
  esac
fi
