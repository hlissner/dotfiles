#!/usr/bin/env bash

checkupdates >/dev/null
echo "U$(pacaur -Qu | wc -l)"
