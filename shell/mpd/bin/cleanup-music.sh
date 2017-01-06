#!/usr/bin/env bash

# Delete all songs that are in the delete-pls playlist, and cleans up any empty folders
# it leaves behind.

set -e

playlistdir="$(grep playlist_directory $HOME/.config/mpd/mpd.conf | awk '{ print $2; }')"
playlistdir="${playlistdir//\"/}"
playlistfile="$playlistdir/1-star.m3u"
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

# Remove duplicates in playlists
for playlist in "$playlistdir"/*.m3u; do
    awk '!seen[$0]++' "$playlist" > "${playlist}.tmp"
    if [[ -f "${playlist}.tmp" ]]; then
        rm -f "$playlist"
        mv "${playlist}.tmp" "$playlist"
    fi
done

# Remove empty directories
find "$HOME/music" -type d -empty -delete
