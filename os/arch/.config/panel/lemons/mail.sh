#!/usr/bin/env bash

[ -f ~/.secrets/accounts.sh ] && . ~/.secrets/accounts.sh || exit

feed=$(curl -u "${MAIL_USER}:${MAIL_PASS}" --silent https://mail.google.com/mail/feed/atom)
con=$(echo $feed | grep -c "<fullcount>")
num=$(echo $feed | grep -o "<entry>" | wc -l)

if [ "$con" -eq 1 ]
then
    # if [ "$num" -gt 0 ]; then
        # oldnum=0
        # [ -f /tmp/newmail ] && oldnum=$(cat /tmp/newmail)
        # echo "$num" > /tmp/newmail
        # if [ "$num" -ne "$oldnum" ]
        # then
        #     notify-send 'New email'
        # fi
    # fi
    echo "M$num"
else
    echo "M!"
fi
