#!/usr/bin/env janet
# Regression tests for config/zsh/completions/_hey.

(use judge)
(use sh)
(import hey)

(def- driver (hey/path :home "test/hey/completion.d/driver.zsh"))
(def- null (file/open "/dev/null"))
# janet-sh routes a redirect into a buffer through file/temp, which always
# writes to /tmp. Capturing into hey's own runtime directory keeps these tests
# runnable where /tmp isn't writable; it's tmpfs, so it clears at logout.
(def- scratch
  (let [dir (hey/path :runtime "test.d")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    (hey/path/join dir "test-completion.out")))

(defn- complete
  "Run CASE with WORDS and return _hey's offers, one string per line."
  [case & words]
  (with [out (file/open scratch :w)]
    ($? zsh ,driver ,case ,;words > ,out > [stderr null]))
  (filter |(not (empty? $)) (string/split "\n" (string/trim (slurp scratch)))))

(defn- offers?
  "True if any line of the completion OUT contains TEXT."
  [out text]
  (not= nil (some |(string/find text $) out)))


(deftest completion/subcommand-arguments
  # From bin/hey.d/sync.janet comment header (OPTIONS: and ARGUMENTS:).
  (def out (complete "dispatch" "sync" ""))
  (test (offers? out "--fast[") true)
  (test (offers? out "--host[") true)
  (test (offers? out "rollback:") true)

  (deftest "A command with no documented arguments offers nothing"
    # ops.janet has no arguments documented, so treat it as "takes no
    # arguments", rather than "something went wrong"
    (test (complete "dispatch" "ops" "") @[])))

(deftest completion/hook-areas
  (deftest "The menu carries the sigil, so areas and hooks can share it"
    (test (complete "areas" "") @["DESC[areas] @alpha @beta @host"]))

  (deftest "Past the sigil, the areas are bare"
    (test (complete "areas" "@") @["DESC[areas] alpha beta host"]))

  (deftest "A consumed @AREA leaves the hook name to the rest arguments"
    (test (complete "hookarg" "@alpha") @["HOOKS alpha"])
    (test (complete "hookarg" "onReload") @["DEFAULT"])
    # Only the first of the rest arguments is a hook; the rest belong to it.
    (test (complete "hookarg" "@alpha" "2") @["DEFAULT"]))

  (deftest "reload forwards an area, so it completes them"
    (def out (complete "dispatch" "reload" ""))
    (test (offers? out "__hey_hook_areas") true)))

(deftest completion/paths-are-not-dot-commands
  (test (complete "dispatch" "./foo" "") @["DEFAULT"])
  (test (complete "dispatch" "/abs/foo" "") @["DEFAULT"]))

(deftest completion/command-reconstruction
  # __hey_scriptdir has to rebuild the command line for `hey help --dump`. The
  # sigil belongs to the first word whether the NAME.d walk consumes it or it is
  # the leaf, and @DIR must keep its sigil while wm and host do not.
  (defn- dumped [& words]
    (find |(string/has-prefix? "DUMP " $) (complete "reconstruct" ;words)))

  (test (dumped ".solo" "") "DUMP .solo")
  (test (dumped ".nest" "deep" "") "DUMP .nest deep")
  (test (dumped "wm" "solo" "") "DUMP wm solo")
  (test (dumped "@alpha" "solo" "") "DUMP @alpha solo"))

(deftest completion/script-listing
  (deftest "The .NAME sigil lists the bin directories"
    (test (complete "menu" ".") @["DESC[scripts] nest: solo:A fixture script."]))

  (deftest "@DIR lists the config directories"
    (test (complete "menu" "@") @["WANT[directories] -a _hey_cfgdirs"])))

(deftest completion/degrades-without-hey
  (test (complete "nohey" "sync" "") @[])
  (test (complete "nohey" ".solo" "") @["DEFAULT"])
  (test (complete "nohey" "./foo" "") @["DEFAULT"]))

(deftest completion/empty-word-is-not-a-bare-dump
  # `hey '' <TAB>` must not run a bare `hey help --dump`
  (def out (complete "dispatch" "" ""))
  (test (offers? out "build:Build nix images") false))
