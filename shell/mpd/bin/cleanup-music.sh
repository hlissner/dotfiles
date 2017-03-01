#!/usr/bin/env bash

# Delete all songs that are in the delete-pls playlist, and cleans up any empty folders
# it leaves behind.

set -e
shopt -s nullglob

playlistdir=$(grep playlist_directory "$HOME/.config/mpd/mpd.conf" | awk '{ print $2; }')
playlistdir="${playlistdir//\"/}"
playlistfile="${playlistdir/#\~/$HOME}/1-star.m3u"
songs=$(cat "$playlistfile")

# Delete designated songs
IFS="
"
declare -a to_delete=()
for song in "${songs[@]}"; do
    fpath="$HOME/music/$song"
    if [[ -f $fpath ]]; then
        to_delete+=("$fpath")
        # echo "Deleting: $song"
        # rm -f "$fpath"
    fi
done

if (( ${#to_delete[@]} == 0 )); then
    echo "Nothing to delete"
    exit
fi

printf "Deleting %s songs:\n\n%s\n\nConfirm? (y/n) " \
    "${#to_delete[@]}" \
    "$(IFS=$'\n'; printf "%s" "${to_delete[*]}")"
read -r confirm
case $confirm in
    y|Y)
        echo "Deleting..."
        for file in ${to_delete[@]}; do
            rm -fv "$file"
        done
        ;;
    n|N) echo "Aborted"; exit ;;
    *) echo "Invalid" ;;
esac
:>"$playlistfile"

# Remove duplicates in playlists
for playlist in "$playlistdir"/*.m3u; do
    awk '!seen[$0]++' "${playlist}" > "${playlist}.tmp"
    if [[ -f "${playlist}.tmp" ]]; then
        rm -f "$playlist"
        mv "${playlist}.tmp" "$playlist"
    fi
done

# Remove empty directories
find "$HOME/music" -type d -empty -delete
