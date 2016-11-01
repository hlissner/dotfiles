#!/usr/bin/env bash

while :
do
    echo "U"$(checkupdates | wc -l)
    sleep 3600
done
