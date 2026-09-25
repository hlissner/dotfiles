#!/usr/bin/env zsh
# Convert the installed Nix's own manual into markdown at data/refs/nix.

source ${0:A:h}/lib/reference.zsh

key=$(pkgver nix) || die "nix isn't installed"

build() {
  # Already on disk if documentation.enable is on (the default)...
  local manual=/run/current-system/sw/share/doc/nix/manual
  if [[ ${manual:A} != /nix/store/*-nix-manual-$key/* ]]; then
    # ...and otherwise the same manual, if nixpkgs' default nix is the
    # installed one. The version check below says whether it is.
    manual=$(nix build --no-link --print-out-paths nixpkgs#nix.doc)/share/doc/nix/manual
    [[ ${manual:A} == /nix/store/*-$key-doc/* ]] || {
      print -u2 "can't find a manual for nix $key (nixpkgs#nix.doc is ${${manual:A}#/nix/store/})"
      return 1
    }
  fi
  html2md $manual .
}

ensure $key
