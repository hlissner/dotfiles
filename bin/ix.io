#!/usr/bin/env zsh
# Sends file(s) or stdin to a ix.io
set -e

_usage() {
  more <<EOL
Usage: ${0:A:t} [FILE...]

Uploads text files/stdin to ix.io.

Options:
  -l LANG   Specify file extension for syntax highlight
  -h        This information

Examples:
  ${0##*/} script.py
  ${0##*/} -l py sometext
  echo "Hello world" | ${0:A:t}
  echo "puts 'Hi'" | ${0:A:t} -l rb
EOL
}

#
while getopts hl: opt; do
  case $opt in
    l)  lang="?$OPTARG"
        ;;
    [h?]) _usage; exit; ;;
    :)  >&2 echo "$OPTARG requires an argument"
        _usage
        exit 1
        ;;
  esac
done
shift $((OPTIND-1))

if (($# == 0)) && [[ -t 0 ]]; then
  >&2 echo "Nothing in stdin and no files specified!"
  >&2 _usage
  exit 1
fi

url=$(cat "$@" | curl -s -F 'f:1=<-' ix.io)

# Naive lang detection from file extension
[[ $1 == *.* && -z $lang ]] && lang="${1##*.}"
# Show url
url=$(printf "%s/%s" "$url" "$lang")
echo $url | clip
echo $url
