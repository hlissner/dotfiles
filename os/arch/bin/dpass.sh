#!/usr/bin/env bash

shopt -s nullglob globstar

prefix=${PASSWORD_STORE_DIR-~/.password-store}
password_files=( "$prefix"/**/*.gpg  )
password_files=( "${password_files[@]#"$prefix"/}"  )
password_files=( "${password_files[@]%.gpg}" )

entry=$(printf "%s\n" "${password_files[@]}" | rofi -dmenu -p pass: "$@")

[[ -n $entry ]] || exit
out=$(pass show "$entry")

[[ $out ]] || exit
fields=$(echo "$out" | cut -d: -f1 | tail -n +2)
field=$(printf "password\n%s\n" "${fields[@]}" | rofi -dmenu -p pass:field:)

case "$field" in
    password)
        pass -c "$entry"
        ;;
    *)
        echo "$out" | grep "^${field}:" | awk '{print $2}' | xclip -selection clipboard -in
        ;;
esac
