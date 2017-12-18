#!/usr/bin/env bash

if (( $# == 0 )); then
  >&2 echo "Forgot to specify a destination filename. Aborting."
  exit 1
fi

# Upload file/stdin to transfer.sh
url="https://transfer.sh"
tmpfile=$(mktemp -t transferXXX)
cleanup() { rm -f "$tmpfile"; }
trap cleanup EXIT

if tty -s; then
  basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g')
  curl --progress-bar --upload-file "$1" "$url/$basefile" >>"$tmpfile"
else
  curl --progress-bar --upload-file "-" "$url/$1" >>"$tmpfile"
fi

cat "$tmpfile" | clip
cat "$tmpfile"
