#!/usr/bin/env bash

[ -f ~/.secrets/accounts.sh ] && . ~/.secrets/accounts.sh || exit

get-mail() {
    local feed=$(curl -u "$1:$2" --silent https://mail.google.com/mail/feed/atom)
    if [ "$(echo $feed | grep -c "<fullcount>")" -eq 1 ]
    then
        echo $feed | grep -o "<entry>" | wc -l
    else
        >&2 echo "mail.sh: error with $1"
        echo 0
    fi
}

a=$(get-mail "${MAIL1[USER]}" "${MAIL1[PASS]}")
b=$(get-mail "${MAIL2[USER]}" "${MAIL2[PASS]}")
c=$(get-mail "${MAIL3[USER]}" "${MAIL3[PASS]}")

echo M$(( $a + $b + $c ))
