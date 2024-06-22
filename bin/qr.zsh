#!/usr/bin/env zsh
# Create a QR code from FILE or stdin.
#
# SYNOPSIS:
#   hey .qr FILE
#   echo TEXT | hey .qr

cat $@ | hey.do -! -p libqrencode qrencode -t ansiutf8
