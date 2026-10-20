#!/usr/bin/env zsh
# Copy the niri wiki, at the revision that is installed, into data/refs/niri.

source ${0:A:h}/lib/reference.zsh

key=$(pkgver niri) || die "niri isn't installed"
src=$(nixpath niri) || die "niri isn't a flake input of the installed system"

build() {
  # The wiki rides along in niri's source tree, and that tree is a flake input
  # of niri-flake's -- already in the store, since the system was evaluated
  # from it. Asking for the package's doc output instead means a cache miss
  # compiles the compositor for the sake of some markdown. Which of the two
  # packages modules/wm/niri picked is readable off the binary's store path.
  local pkg=niri-stable doc
  [[ ${commands[niri]:A} == */niri-unstable-* ]] && pkg=niri-unstable
  doc=$(nix eval --raw "$src#$pkg.src.outPath") || return
  # Pages at the root, under the wiki's own names (Configuration:-Input.md,
  # colon and all); _Sidebar.md is the TOC. --no-preserve=mode or the store's
  # read-only bits come along and the prune below can't touch what it copied.
  cp -r --no-preserve=mode $doc/docs/wiki/. .
  # The only complete statement of what config.kdl accepts.
  cp --no-preserve=mode $doc/resources/default-config.kdl .
  # Logos and a stylesheet; examples/ stays, the Animations page refers to it.
  rm -rf _assets logo
}

ensure $key
