#!/usr/bin/env zsh
# Rate the song Supersonic is playing, or its album/album artist.
#
# SYNOPSIS:
#   hey @supersonic rate [--album|--artist] [RATING]
#
# DESCRIPTION:
#   Without a RATING, asks for one in rofi. Songs are rated through Supersonic
#   so its own stars update; albums and artists go straight to the Subsonic
#   server, since its IPC has nothing for them.
#
# OPTIONS:
#   --album
#     Rate the song's album instead of the song.
#   --artist
#     Rate the album's artist instead of the song.
#
# ARGUMENTS:
#   1 RATING
#     0  -- Unrated
#     1
#     2
#     3
#     4
#     5

setopt err_exit pipe_fail
source ${0:A:h}/lib/subsonic.zsh

local -a what
zparseopts -D -F -- -album=what -artist=what || exit 1
local kind=${${what[1]:-song}#--}

local id name sub cover before
subsonic.playing $kind
before=$(subsonic.api get${(C)kind} id=$id | jq -r ".$kind.userRating // 0")

local rating=${1-}
if [[ -z $rating ]]; then
  rating=$(hey @rofi read -P "Rate \"$name\" (0-5)" ${cover:+-I} $cover) || exit 1
  [[ -n $rating ]] || exit 1
fi
[[ $rating == [0-5] ]] || hey.abort "Not a rating between 0 and 5: $rating"

if [[ $kind == song ]]; then
  hey.do supersonic -rate-current $rating
else
  hey.do subsonic.api setRating id=$id rating=$rating >/dev/null
fi

.stars() { print -r -- ${(r:5::☆:)${(l:$1::★:)}} }
local body="$(.stars $before) → $(.stars $rating)"
[[ -z $sub ]] || body="$sub"$'\n'"$body"
hey.toast -a Supersonic ${cover:+-i} $cover info "Rated: $name" "$body"
