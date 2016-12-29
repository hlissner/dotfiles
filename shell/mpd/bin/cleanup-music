#!/usr/bin/env bash

# Delete all songs that are in the delete-pls playlist, and cleans up any empty folders
# it leaves behind.

set -e

playlistfile=$HOME/music/.db/playlists/delete-pls.m3u
songs=$(<"$playlistfile")

# Delete designated songs
IFS="
"
for song in ${songs[@]}; do
    fpath="$HOME/music/$song"
    if [[ -f $fpath ]]; then
        echo "Deleting: $song"
        rm -f "$fpath"
    fi
done
:>"$playlistfile"

# Remove empty directories
find "$HOME/music" -type d -empty -delete
