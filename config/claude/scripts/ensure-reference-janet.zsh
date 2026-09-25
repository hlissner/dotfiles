#!/usr/bin/env zsh
# Mirror the Janet manual into data/refs/janet, plus the core API as the
# installed interpreter documents it.
#
# janet-lang.org has no tags or release branches, so the manual is the site as
# it stood when the installed version was tagged. Close, not exact; core-api.md
# is exact by construction, so it's the one to trust.

source ${0:A:h}/lib/reference.zsh

key=$(pkgver janet) || die "janet isn't installed"

build() {
  local janet=$(gitrepo https://github.com/janet-lang/janet)
  local site=$(gitrepo https://github.com/janet-lang/janet-lang.org)
  # Only the tag's date is wanted, so neither its history nor its blobs
  git -C $janet fetch -q --depth=1 --filter=blob:none origin tag v$key
  git -C $site fetch -q origin +refs/heads/master:refs/heads/master
  local date=$(git -C $janet log -1 --format=%cI v$key)
  local rev=$(git -C $site rev-list -1 --before=$date master)
  [[ -n $rev ]] || { print -u2 "janet-lang.org has no commit before $date"; return 1 }
  print -r -- "janet-lang.org@$rev" > .site-revision

  # .mdz is just markdown with @code`...` for spans
  mkdir manual api-prose
  git -C $site archive ${rev}:content/docs | tar -x -C manual
  git -C $site archive ${rev}:content/api | tar -x -C api-prose

  # root-env iterates in hash order; sort, or every rebuild reshuffles it
  janet -e '
    (def entries @[])
    (eachp [k v] root-env
      (when (and (symbol? k) (get v :doc))
        (array/push entries [(string k) (get v :doc)])))
    (sort-by first entries)
    (print "# Janet " janet/version " core API")
    (print)
    (print "Dumped from the installed interpreter; exact by construction.")
    (print)
    (each [name doc] entries
      (print "## " name)
      (print)
      (print doc)
      (print))
  ' > core-api.md
  [[ -s core-api.md ]] || { print -u2 "janet dumped no docstrings"; return 1 }
}

ensure $key
