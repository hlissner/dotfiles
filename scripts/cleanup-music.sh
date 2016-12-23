#!/usr/bin/env bash

# Delete all songs that are in the delete-pls playlist, and cleans up any empty folders
# it leaves behind.

playlistfile=$HOME/music/.playlists/delete-pls.m3u
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

# Remove empty directories in two passes
find "$HOME/music" -maxdepth 2 -type d -empty -delete
find "$HOME/music" -maxdepth 1 -type d -empty -delete
