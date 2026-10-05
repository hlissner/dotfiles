#!/usr/bin/env zsh
# Toggle "favorite" on the song Supersonic is playing, or its album/album artist.
#
# SYNOPSIS:
#   hey @supersonic favorite [--album|--artist] [STATE]
#
# DESCRIPTION:
#   Supersonic can rate the current track over IPC but not favorite it, so this
#   goes around it: straight to the Subsonic server it's logged into, using the
#   password it parked in the keyring. Supersonic's own hearts won't notice
#   until the track changes.
#
# OPTIONS:
#   --album
#     The song's album instead of the song.
#   --artist
#     The album's artist instead of the song.
#
# ARGUMENTS:
#   1 STATE
#     on   -- Favorite it.
#     off  -- Unfavorite it. Without either, toggle.

setopt err_exit pipe_fail
source ${0:A:h}/lib/subsonic.zsh

local -a what
zparseopts -D -F -- -album=what -artist=what || exit 1
local kind=${${what[1]:-song}#--}

local id name sub cover
subsonic.playing $kind

local state=${1-}
if [[ -z $state ]]; then
  local starred
  starred=$(subsonic.api get${(C)kind} id=$id | jq -r ".$kind.starred // empty")
  [[ -n $starred ]] && state=off || state=on
fi
[[ $state == (on|off) ]] || hey.abort "Not on or off: $state"

# star/unstar want to be told what kind of id they're given.
local -A verb=( on star off unstar ) key=( song id album albumId artist artistId )
hey.do subsonic.api $verb[$state] $key[$kind]=$id >/dev/null

local label="♡ Unfavorited"
[[ $state == on ]] && label="♥ Favorited"
hey.toast -a Supersonic ${cover:+-i} $cover info "$label: $name" "$sub"
