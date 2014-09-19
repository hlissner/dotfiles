#!/bin/sh

git filter-branch \
    --subdirectory-filter "$@" \
    --tag-name-filter cat \
    --prune-empty -- --all
