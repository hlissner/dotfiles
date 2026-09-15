#!/usr/bin/env janet
# Regression tests for bin/heyops and bin/heyops.d/*.
#
# Nothing here goes near another machine: every subcommand's first act is to ssh
# somewhere, so what's left to pin is everything that happens before that -- the
# role gate, the dispatch table, and the headers _heyops completes from.

(use judge)
(use sh)
(import hey)

(def- bin (hey/path :home "bin/heyops"))
(def- fixtures (hey/path :test "heyops/heyops.d"))
# Read off disk rather than listed here, so a new script is tested the moment
# it exists rather than the moment someone remembers this file.
(def- scripts
  (sorted (map |(string/replace ".janet" "" $0) (os/dir (hey/path :home "bin/heyops.d")))))

(defn- heyops
  ``Run heyops with ROLE's fixture info.json, and return [exit-code output].
  Both streams into the one buffer, because the interesting half of this lands
  on stderr.``
  [role & args]
  (def out @"")
  (def code
    (hey/with-envvars ["XDG_DATA_HOME" (hey/path/join fixtures role)]
      (first (run ,bin ,;args > ,out > [stderr out]))))
  [code (string/trim out)])

(defn- says? [[_ out] text] (not= nil (string/find text out)))

(defn- dump [& args] (string/split "\n" (last (heyops "workstation" "help" "--dump" ;args))))

# The lines before the first blank one: `help --dump` emits commands, then
# aliases, then the sigil patterns.
(defn- commands []
  (seq [line :in (dump) :until (empty? line)]
    (first (string/split ":" line))))


(deftest heyops/role-gate
  # A non-workstation is a clean abort. So is a $XDG_DATA_HOME with nothing in
  # it, the way a fresh install or a box that got the binary but not the flake
  # looks: flake/info slurps, so without the guard in bin/heyops that was a
  # stack trace and an exit 1 instead.
  (test (first (heyops "server" "info" "somehost")) 127)
  (test (first (heyops "no-such-fixture" "info" "somehost")) 127))

(deftest heyops/usage
  # Every subcommand quotes its own SYNOPSIS: rather than keeping a second copy
  # of it in an abort, so this is really a test that the header is reachable at
  # runtime -- including from the compiled binary, where :current-file is
  # relative to the project root.
  (test (filter |(not (says? (heyops "workstation" $0) "Usage:")) scripts) @[]))

(deftest heyops/dispatch-table
  # The gap this closes: adding bin/heyops.d/foo.janet and forgetting either
  # the import or the dispatch entry in bin/heyops leaves a script that only
  # exists on disk.
  (def menu (commands))
  (test (filter |(not (index-of $0 menu)) scripts) @[]))

(deftest heyops/system-argument
  # Every subcommand but edit names a machine first, and says so in a way
  # _heyops can complete. A header that forgets the @hosts ref still runs; it
  # just quietly stops completing hostnames, which is the sort of thing nobody
  # notices. (edit's SYSTEM:FILE is pinned in completion.janet.)
  (test (filter |(not (index-of "1:system:hey.comp.hosts" (dump $0)))
                (filter |(not= $0 "edit") scripts))
        @[]))
