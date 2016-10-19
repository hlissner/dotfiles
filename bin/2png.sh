#!/usr/bin/env zsh

# Creates pngs from PSD (and AI) files. Requires imagemagick (and ghostscript
# for ai files)

# Usage: 2png *.{psd,ai}

[[ ! -d _png ]] && mkdir -p _png;

for f in $1
do
    convert -resize 1200x1200 ${f}[0] _png/${f}.png
done
