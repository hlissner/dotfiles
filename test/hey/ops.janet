#!/usr/bin/env janet
# Regression tests for bin/hey.d/ops.janet, bin/hey.d/ops.d/* and
# lib/hey/ops.janet.
#
# Nothing here goes near another machine: every subcommand's first act is to ssh
# somewhere, so what's left to pin is everything that happens before that -- the
# role gate, the dispatch table, the headers _hey completes from, and the two
# functions that decide what an ssh round trip says.

(use judge)
(use sh)
(import hey)
(import hey/ops)

(def- bin (hey/path :home "bin/hey"))
(def- fixtures (hey/path :test "hey/ops.d"))
# Read off disk rather than listed here, so a new script is tested the moment
# it exists rather than the moment someone remembers this file.
(def- scripts
  (sorted (seq [file :in (os/dir (hey/path :home "bin/hey.d/ops.d"))
                :when (string/has-suffix? ".janet" file)]
            (hey/string/no-suffix ".janet" file))))

(defn- hey-ops
  ``Run `hey ops ARGS` with ROLE's fixture info.json, and return [exit-code
  output]. Both streams into the one buffer, because the interesting half of
  this lands on stderr.``
  [role & args]
  (def out @"")
  (def code
    (hey/with-envvars ["XDG_DATA_HOME" (hey/path/join fixtures role)]
      (first (run ,bin ops ,;args > ,out > [stderr out]))))
  [code (string/trim out)])

(defn- says? [[_ out] text] (not= nil (string/find text out)))

(defn- dump [role & args]
  (def out @"")
  (hey/with-envvars ["XDG_DATA_HOME" (hey/path/join fixtures role)]
    ($? ,bin help --dump ops ,;args > ,out))
  (string/split "\n" (string out)))

# The lines before the first blank one: `help --dump` emits commands, then
# aliases, then the sigil patterns.
(defn- commands []
  (seq [line :in (dump "workstation") :until (empty? line)]
    (first (string/split ":" line))))


(deftest ops/role-gate
  # A non-workstation is a clean abort. So is a $XDG_DATA_HOME with nothing in
  # it, the way a fresh install or a box that got the binary but not the flake
  # looks: flake/info slurps, so without the guard in bin/hey.d/ops.janet that
  # was a stack trace and an exit 1 instead.
  (test (first (hey-ops "server" "info" "somehost")) 127)
  (test (first (hey-ops "no-such-fixture" "info" "somehost")) 127)
  # The gate is the :rules fn, so anything that needs the rules is gated, docs
  # and completion included. hey's own menu doesn't run it, so ops is still in
  # that everywhere.
  (test (index-of "1:system:hey.comp.hosts" (dump "server" "info")) nil))

(deftest ops/usage
  # Every subcommand quotes its own SYNOPSIS: rather than keeping a second copy
  # of it in an abort, so this is really a test that the header is reachable at
  # runtime -- including from the compiled binary, where :current-file is
  # relative to the project root.
  (test (filter |(not (says? (hey-ops "workstation" $0) "Usage:")) scripts) @[])
  # Bare, it's the menu, and help/which aren't on it: they're hey's, and don't
  # work one level down.
  (def bare (hey-ops "workstation"))
  (test (first bare) 1)
  (test (says? bare "- push-keys -- ") true)
  (test (says? bare "- help") false))

(deftest ops/dispatch-table
  # The gap this closes: adding bin/hey.d/ops.d/foo.janet and forgetting either
  # the import or the rule in bin/hey.d/ops.janet leaves a script that only
  # exists on disk. And the other way around: the menu has no builtins in it.
  (test (deep= (sorted (commands)) scripts) true))

(deftest ops/system-argument
  # Every subcommand but edit names a machine first, and says so in a way _hey
  # can complete. A header that forgets the @hosts ref still runs; it just
  # quietly stops completing hostnames, which is the sort of thing nobody
  # notices. (edit's SYSTEM:FILE is pinned in completion.janet.)
  (test (filter |(not (index-of "1:system:hey.comp.hosts" (dump "workstation" $0)))
                (filter |(not= $0 "edit") scripts))
        @[]))

(deftest ops/ssh-dir
  # modules.xdg.ssh moves ~/.ssh out from under itself, and only workstations
  # turn it on. Expanded by the remote shell, so these stay literal.
  (test (map ops/ssh-dir ["workstation" "server" nil])
        @["$HOME/.config/ssh" "$HOME/.ssh" "$HOME/.ssh"]))
