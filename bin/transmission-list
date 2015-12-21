#!/usr/bin/env zsh

# Pretty print remote transmission torrents. Takes one argument: the server hostname/ip

local results
results=`transmission-remote "$1" -l | \
    awk 'NR > 1 { s = ""; for (i = 10; i <= NF; i++) s = s $i " "; print $9 " | " s  }' | \
    sed '$d' | \
    perl -pe 's/\s\[[a-zA-Z0-9]+\]\s/ /g'` && echo "$results" || echo "No torrents!"

