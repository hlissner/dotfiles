#!/usr/bin/env zsh
# Import a GPG private/public key pair and ultimate-trust it.
#
# SYNOPSIS:
#   gpg-import KEYFILE...
#
# DESCRIPTION:
#   Imports every key given, then marks each fingerprint in the private key as
#   ultimately trusted (ownertrust 6). Order doesn't matter: gpg is asked what
#   each file holds, so the private key is whichever one has a 'sec' record.
#   Passing only the private key works too, if it carries the public half (as
#   --export-secret-keys output does).
#
#   A passphrase-protected private key will prompt via pinentry; this isn't
#   unattended-safe without --pinentry-mode loopback.
#
#   I wrote this because I do this so seldomly that I often forget the
#   incanation.
#
# EXAMPLES:
#   hey .gpg-import me.pub me.key
#   hey .gpg-import me.key
#
# ARGUMENTS:
#   * KEYFILE @files

set -euo pipefail

# True if the file holds a secret key.
is-private() {
  gpg --batch --with-colons --import-options show-only --import $1 2>/dev/null \
    | grep -q '^sec:'
}

local pub priv
for f in $@; do
  if is-private $f; then priv=$f; else pub=$f; fi
done
[[ -n $priv ]] || { print -u2 "no private key among: $@"; exit 1 }

gpg --batch --import $pub $priv
gpg --batch --with-colons --import-options show-only --import $priv \
  | awk -F: '$1 == "fpr" { print $10 ":6:" }' \
  | gpg --batch --import-ownertrust
gpg --check-trustdb
