#!/usr/bin/env bash

if ! pgrep weechat >/dev/null; then
    >&2 echo "Weechat isn't running, or fifo is off: /fifo enable"
    exit 1
fi

if [[ -f ~/.private/config/irc.conf ]]; then
    # ...otherwise, configure it!
    CWD=$(cd $(dirname $0) && pwd -P)

    wee "$HOME/.private/config/irc.conf"
    wee "$CWD/../plugins.txt"
    wee "$CWD/../settings.txt"
    wee "$CWD/../servers.txt"
else
    >&2 echo "Couldn't find secrets!"
    exit 1
fi
