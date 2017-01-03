#!/usr/bin/env bash

if [[ ! -f "$HOME/.private/config/pushover.conf" ]]; then
    >&2 echo "No pushover config file found (~/.private/config/pushover.conf)"
    exit 1
fi

message=
title=
priority=
url=
device=

while getopts t:m:p:u:d: opt; do
    case $opt in
        t) title="$OPTARG" ;;
        m) message="$OPTARG" ;;
        p) priority="$OPTARG" ;;
        u) url="$OPTARG" ;;
        U) url_title="$OPTARG" ;;
        d) device="$OPTARG" ;;
        *) >&2 echo "Invalid option $OPTARG"
           exit 1
           ;;
    esac
done
shift $((OPTIND-1))

. "$HOME/.private/config/pushover.conf"

curl -s \
    --form-string "token=$TOKEN" \
    --form-string "user=$USER" \
    --form-string "title=$title" \
    --form-string "message=$message" \
    --form-string "url=$url" \
    --form-string "url_title=$url_title" \
    --form-string "device=$device" \
    https://api.pushover.net/1/messages.json
