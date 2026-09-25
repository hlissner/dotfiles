#!/usr/bin/env zsh
# Copy Noctalia's docs, from the revision that's installed, into
# data/refs/noctalia.

source ${0:A:h}/lib/reference.zsh

version=$(pkgver noctalia) || die "noctalia isn't installed"
# The flake input it was built from, when there is one: noctalia is pinned to
# master, which carries the last release's version number for weeks.
src=$(nixpath noctalia) || src=

build() {
  if [[ ! -d $src/docs ]]; then
    src=$PWD/.src
    local repo=$(gitrepo https://github.com/noctalia-dev/noctalia)
    git -C $repo fetch -q --depth=1 origin tag v$version
    mkdir $src
    git -C $repo archive v$version | tar -x -C $src
  fi
  # --no-preserve=mode or the store's read-only bits come along and the prune
  # below can't touch what it copied.
  cp -r --no-preserve=mode $src/docs/. .
  # 11 of the 12 megabytes are screenshots, and a screenshot is the one thing
  # in here an agent can't grep.
  find . -type d -name assets -prune -exec rm -rf {} +
  # The top-level notes aren't in docs/ but answer more questions than half of
  # what is. example.toml doubly so -- it's the only complete statement of
  # what config.toml accepts.
  local f
  for f in README.md BUILDING.md PACKAGING.md CONTRIBUTING.md example.toml; do
    [[ -e $src/$f ]] && cp --no-preserve=mode $src/$f .
  done
  rm -rf .src
}

ensure "$version${src:+ ${src:t}}"
