#!/usr/bin/env zsh

hey.requires yt-dlp

yt-dlp --newline \
    --ignore-config \
    --no-playlist \
    -o "%(title).200s-%(id)s.%(ext)s" \
    --output-na-placeholder "NA" \
    -P ~/downloads/music \
    -f bestaudio \
    --extract-audio \
    --audio-quality 0 \
    --audio-format mp3 \
    --embed-thumbnail \
    --compat-options 2022 \
    --progress-template "download:[download] downloaded_bytes:%(progress.downloaded_bytes)s ETA:%(progress.eta)s total_bytes_estimate:%(progress.total_bytes_estimate)s total_bytes:%(progress.total_bytes)s progress.speed:%(progress.speed)s filename:%(progress.filename)s" \
    "$@"
