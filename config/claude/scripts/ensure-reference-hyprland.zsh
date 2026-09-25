#!/usr/bin/env zsh
# Mirror the Hyprland wiki, as built for the installed version, into
# data/refs/hyprland as markdown.

source ${0:A:h}/lib/reference.zsh

# "0.56.0+date=2026-09-19_83cf6a6" -> "0.56.0", same way the wiki versions.
# hyprctl, because Hyprland itself is behind a /run/wrappers shim.
key=$(pkgver hyprctl) || die "hyprland isn't installed"
key=${key%%+*}

build() {
  local base=https://wiki.hypr.land/$key
  curl -fsSL $base/sitemap.xml -o .sitemap.xml
  grep -oE '<loc>[^<]+</loc>' .sitemap.xml | sed -E 's:</?loc>::g' \
    | grep "^$base/" | sort -u > .urls
  [[ -s .urls ]] || {
    print -u2 "wiki.hypr.land has no $key build; check its version selector"
    return 1
  }
  mirror $base .html index.html < .urls
  html2md .html .
  rm -rf .html .sitemap.xml .urls
}

ensure $key
