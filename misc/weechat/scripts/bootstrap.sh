#!/usr/bin/env zsh

if ! pgrep weechat >/dev/null; then
  >&2 echo "Weechat isn't running"
  exit 1
elif [[ ! -e ~/.weechat/weechat_fifo ]]; then
  >&2 echo "Weechat fifo is off, run /fifo enable"
  exit 2
fi

wee "/secure passphrase $(pass irc/master)"
wee "/secure set username $(pass-get irc/master user)"
wee "/secure set freenode $(pass irc/freenode.net | head -n1)"
wee "/secure set snoonet $(pass irc/snoonet.org | head -n1)"
wee "/secure set oftc $(pass irc/oftc.net | head -n1)"
wee "/secure set afternet $(pass irc/afternet.net | head -n1)"
wee "/secure set pushover_key $(pass api/pushover | head -n1)"

wee "${0:A:h}/../plugins.txt"
wee "${0:A:h}/../settings.txt"
wee "${0:A:h}/../servers.txt"
