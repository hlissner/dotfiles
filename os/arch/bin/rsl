#!/usr/bin/env bash

# Run resilio (bittorrent sync) from $HOME if it isn't running. Otherwise, open
# its gui in the browser.

open="open"
[[ $OSTYPE == linux* ]] && open="xdg-open"

if ! pgrep rslsync >/dev/null; then
    pushd $HOME >/dev/null
    rslsync &
    popd >/dev/null
fi

[[ -t 0 ]] && $open http://localhost:8888/gui/
