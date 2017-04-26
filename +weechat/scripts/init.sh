#!/usr/bin/env bash

if ! pgrep weechat >/dev/null; then
    >&2 echo "Weechat isn't running, or fifo is off: /fifo enable"
    exit 1
fi

if [[ -f ~/.private/config/irc.conf ]]; then
    # ...otherwise, configure it!
    CWD=$(cd $(dirname $0) && pwd -P)

    wee "/secure passphrase $(pass irc/master)"
    wee "/secure set username vnought"
    wee "/secure set freenode $(pass irc/freenode.net | head -n1)"
    wee "/secure set snoonet $(pass irc/snoonet.org | head -n1)"
    wee "/secure set oftc $(pass irc/oftc.net | head -n1)"
    wee "/secure set afternet $(pass irc/afternet.net | head -n1)"
    wee "/secure set pushover_key $(pass api/pushover/key)"
    wee "/secure set pushover_api $(pass api/pushover/api)"

    wee "$CWD/../plugins.txt"
    wee "$CWD/../settings.txt"
    wee "$CWD/../servers.txt"
else
    >&2 echo "Couldn't find secrets!"
    exit 1
fi
