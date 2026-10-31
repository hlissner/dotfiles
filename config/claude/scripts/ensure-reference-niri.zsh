#!/usr/bin/env zsh
# Copy the niri wiki, at the revision that is installed, into data/refs/niri.

source ${0:A:h}/lib/reference.zsh

key=$(pkgver niri) || die "niri isn't installed"
src=$(nixpath niri) || die "niri isn't a flake input of the installed system"

build() {
  # The wiki rides along in niri's source tree, which *is* the flake input
  # (modules/wm/niri builds upstream's own flake) -- already in the store,
  # since the system was evaluated from it; no package output involved.
  # Pages at the root, under the wiki's own names (Configuration:-Input.md,
  # colon and all); _Sidebar.md is the TOC. --no-preserve=mode or the store's
  # read-only bits come along and the prune below can't touch what it copied.
  cp -r --no-preserve=mode $src/docs/wiki/. .
  # The only complete statement of what config.kdl accepts.
  cp --no-preserve=mode $src/resources/default-config.kdl .
  # Logos and a stylesheet; examples/ stays, the Animations page refers to it.
  rm -rf _assets logo
}

ensure $key
