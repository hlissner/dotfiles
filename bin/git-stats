#!/bin/bash

set -e

git rev-list --max-count=10 --reverse HEAD |
while read rev; do
    git log --oneline -1 $rev
    git ls-tree -r $rev |
        awk '{print $3}' |
        xargs git show
done
