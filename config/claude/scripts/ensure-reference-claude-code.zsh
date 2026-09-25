#!/usr/bin/env zsh
# Mirror code.claude.com/docs into data/refs/claude-code.
#
# The docs are a rolling release with no versioned builds, so this is
# upstream's latest as of whenever the installed CLI last changed version --
# near enough to what's installed, and it keeps me from re-scraping ~200 pages
# per session.

source ${0:A:h}/lib/reference.zsh

key=$(pkgver claude) || die "claude-code isn't installed"

build() {
  local base=https://code.claude.com/docs/en/
  curl -fsSL https://code.claude.com/docs/llms.txt -o INDEX.txt
  grep -oE 'https://code\.claude\.com/docs/en/[^)]+\.md' INDEX.txt | sort -u > .urls
  [[ -s .urls ]] || { print -u2 "llms.txt listed no pages"; return 1 }
  # llms.txt carries a sentence per page (~47KB, ~12k tokens read whole). An
  # agent wants a TOC it can afford to read: section headers plus "path
  # Title", a quarter of the size, minus the translated mirrors. The long one
  # stays for grep.
  sed -E -e '\#docs/_llms/#d' -e '/^- \[/!{/^#/!d}' \
         -e 's#^- \[([^]]+)\]\(https://code\.claude\.com/docs/en/([^)]+)\).*#\2  \1#' \
         INDEX.txt > INDEX.short.txt
  mirror $base . '' < .urls
  rm .urls
}

ensure $key
