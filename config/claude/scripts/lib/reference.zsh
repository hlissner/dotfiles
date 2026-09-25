# Sourced by ../ensure-reference-*.zsh.
#
# Every agent runs one of those before it reads data/refs/NAME, several at a
# time, and mostly to hear "nothing to do". So the fast path is the whole
# design: work out a key naming what's installed (a store path name, never a
# daemon or network round trip), compare it to NAME/.version, leave. Anything
# printed is something an agent pays tokens to read, so the build's chatter
# goes to data/refs/.NAME.log unless DEBUG=1.
#
# A script sets `build` (run in a scratch dir that becomes the tree) and ends
# with `ensure KEY`.

zmodload zsh/system
setopt extended_glob no_unset pipe_fail

REF_NAME=${${ZSH_ARGZERO:t:r}#ensure-reference-}
# :A, not :a -- run as /etc/claude-code/scripts/..., which is only a symlink to
# here, and /etc/claude-code/data won't exist until the next rebuild
# after the directory first does.
REF_ROOT=${ZSH_ARGZERO:A:h:h}
REF_LIB=$REF_ROOT/scripts/lib
REF_DIR=$REF_ROOT/data/refs/$REF_NAME
REF_CACHE=$REF_ROOT/data/repo
REF_REPO=${REF_ROOT:h:h}

[[ ${DEBUG:-0} != (0|) ]] && REF_DEBUG=1 || REF_DEBUG=0

log() { (( REF_DEBUG )) && print -ru2 -- "$REF_NAME: $*"; true }
die() { print -ru2 -- "ensure-reference-$REF_NAME: $*"; exit 1 }

fresh() { [[ -r $REF_DIR/.version && "$(<$REF_DIR/.version)" == "$1" ]] }

ensure() {
  local key=$1
  fresh $key && { log "current: $key"; exit 0 }
  local dir=$REF_DIR:h
  local tmp=$dir/.$REF_NAME.new log=$dir/.$REF_NAME.log lock=$dir/.$REF_NAME.lock lockfd
  # zsystem flock won't create the file itself
  mkdir -p $dir $REF_CACHE && : >>$lock || die "can't create $lock"
  # Blocks while another instance builds. If that one got there, there's
  # nothing left to do; if it died, this one has a go.
  zsystem flock -f lockfd $lock || die "can't lock $lock"
  fresh $key && { log "built by another instance: $key"; exit 0 }

  log "building: $key"
  rm -rf $tmp && mkdir -p $tmp || die "can't create $tmp"
  if (( REF_DEBUG )); then exec 3>&2; else exec 3>$log; fi
  # Not `build || ...`: that context switches err_exit off inside the subshell
  # too. And not a trap, because zsh's err_exit leaves without running one.
  ( cd $tmp && setopt err_exit && build ) >&3 2>&3
  local rc=$?
  exec 3>&-
  if (( rc )); then
    rm -rf $tmp
    (( REF_DEBUG )) || tail -n 5 $log >&2
    die "failed to build $key; the tree left alone (log: $log)"
  fi
  print -r -- $key > $tmp/.version
  # An exchange, so a reader mid-grep gets the old tree or the new one and
  # never a missing one.
  if [[ -d $REF_DIR ]]; then
    mv --exchange -T $tmp $REF_DIR && rm -rf $tmp
  else
    mv -T $tmp $REF_DIR
  fi || die "can't install $REF_DIR"
}


## Helpers

# pkgver CMD -- the version of the package CMD comes from, read off the store
# path it resolves to (what nixpkgs' parseDrvName does), or --version failing
# that.
pkgver() {
  local bin=${commands[$1]:-}
  [[ -n $bin ]] || return 1
  if [[ ${bin:A} == /nix/store/[a-z0-9](#c32)-(#b)([^/]##)/* && $match[1] =~ '-([0-9].*)$' ]]; then
    print -r -- $match[1]
  elif [[ "$($bin --version 2>/dev/null)" =~ '[0-9]+\.[0-9]+(\.[0-9]+)?' ]]; then
    print -r -- $MATCH
  else
    return 1
  fi
}

# nixpath NAME -- NAME's entry in NIX_PATH. Every flake input of the installed
# system is in there (see default.nix), which makes it the cheapest way to ask
# which revision of one is actually installed.
nixpath() {
  local e
  for e in ${(s.:.)NIX_PATH:-}; do
    [[ $e == $1=* ]] && { print -r -- ${e#*=}; return }
  done
  return 1
}

# need CMD... -- put CMDs on PATH, borrowing them from the system's nixpkgs
# when they aren't installed. Build path only, never the fast one.
need() {
  local cmd out
  for cmd in $@; do
    (( $+commands[$cmd] )) && continue
    out=$(nix build --no-link --print-out-paths "nixpkgs#$cmd") || return
    path=(${^${(f)out}}/bin(N/) $path)
    (( $+commands[$cmd] )) || { print -u2 "no $cmd in nixpkgs#$cmd"; return 1 }
  done
}

# gitrepo URL -- a bare clone of URL, cached under data/repo. Fetching is the
# caller's business; it knows which refs it wants.
gitrepo() {
  local dir=$REF_CACHE/${${1:t}%.git}.git
  if [[ ! -d $dir ]]; then
    git init -q --bare $dir && git -C $dir remote add origin $1 || return
  fi
  print -r -- $dir
}

# mirror BASE DIR SUFFIX < urls -- download each URL under BASE to
# DIR/<rest-of-url>SUFFIX. Eight at a time is polite enough not to get
# throttled and still finishes a couple hundred pages in seconds.
mirror() {
  xargs -r -P8 -I{} sh -c '
    rel=${1#"$2"}; rel=${rel#/}
    mkdir -p "$(dirname "$3/$rel$4")"
    curl -fsSL --retry 3 "$1" -o "$3/$rel$4"
  ' _ {} "$1" "$2" "$3"
}

# html2md SRC DEST -- mdBook/Hugo HTML to markdown, keeping the layout.
html2md() {
  need python3 pandoc && python3 $REF_LIB/html2md.py $1 $2
}
