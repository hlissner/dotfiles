#!/usr/bin/env bash

usage() { echo "Usage: $0 [-f <fps>] [-o <output-dest>] [-h]"; }

if (($# == 0)); then
    >&2 echo "No movie file specified"
    exit
elif [[ ! -f $1 ]]; then
    >&2 echo "$1 does not exist"
    exit
fi

fps=30
src="$1"
dest="${${src##*/}%.mov}.gif"
while getopts hf:o: opt; do
    case $opt in
        -f) fps="$OPTARG" ;;
        -o) dest="$OPTARG" ;;
        -h) usage
            exit
            ;;
        :)  >&2 echo "$OPTARG requires an argument"
            usage
            exit 1
            ;;
    esac
done

palette="$(mktemp)"
flags="fps=${fps}"

ffmpeg -v warning -i "$src" -vf "$flags,palettegen" -y "$palette"
ffmpeg -v warning -i "$src" -i "$palette" -lavfi "$flags [x]; [x][1:v] paletteuse" -y "$dest"

[[ -f $palette ]] && rm -f "$palette"
