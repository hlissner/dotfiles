#!/usr/bin/env zsh
# Splits up a flac file into multiple from a *.cue file.
#
# SYNOPSIS:
#   hey .splitflac *.cue *.flac

local cuefile="$1"
local flacfile="$2"
set -e

shnsplit -f "$cuefile" -o flac "$flacfile"
[[ -f split-track00.flac ]] && rm -f split-track00.flac

cuetag.sh "$cuefile" split-track*.flac

for f in split-track*.flac; do
  # TODO: Write to track name
  ffmpeg -i "$f" -map_metadata 0 -c:a libopus -b:a 256k "${f%.flac}.opus"
done

rm -f split-track*.flac
