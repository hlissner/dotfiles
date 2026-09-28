#!/usr/bin/env janet
# Regression tests for lib/zsh/completions/_hey, and for the hey.comp.*
# functions in lib/zsh it's built from.
#
# Everything here fails silently in real life: a broken completion offers
# nothing, and TAB just doesn't do anything.

(use judge)
(use sh)
(import hey :as h)
(import ./../_lib/completion :prefix "")

(def- shim (h/path :home "test/_lib/path/hey"))

(defn- hey [case & words] (complete "hey" case ;words))
(defn- dumped [& words]
  (find |(string/has-prefix? "DUMP " $0) (hey "reconstruct" ;words)))


(deftest completion/subcommand-arguments
  # From bin/hey.d/sync.janet's comment header (OPTIONS: and ARGUMENTS:).
  (def out (hey "dispatch" "sync" ""))
  (test (offers? out "--fast[") true)
  (test (offers? out "build-image:") true))

(deftest completion/sync-arg
  # A position in ARGUMENTS: is absolute, so a value list on `2` would offer
  # itself after every command. What varies with the first argument has to go
  # through the @ref instead, which is what @sync-arg is for.
  (test (hey "syncarg" "build-image" "") @["WANT[variants] -a variants"])
  # Only the first of them; the rest are nixos-rebuild's.
  (test (hey "syncarg" "build-image" "iso" "") @[])
  # Commands that take no such thing are left to zsh.
  (test (hey "syncarg" "switch" "") @["DEFAULT"]))

(deftest completion/ssh-target
  # @ssh-target completes both halves of `lab fs [user@]host[:/path]`, ala _ssh
  (test (hey "call" "__hey_ssh_target" "") @["HOSTS -qS:"])
  (test (hey "call" "__hey_ssh_target" "root@") @["HOSTS -qS:"])
  (test (hey "call" "__hey_ssh_target" "root@nas0.lan:/mnt/ap")
        @["REMOTE[root@nas0.lan] -- ssh /mnt/ap"])
  # Only the first colon belongs to the host.
  (test (hey "call" "__hey_ssh_target" "nas0.lan:/mnt/a:b/")
        @["REMOTE[nas0.lan] -- ssh /mnt/a:b/"]))

(deftest completion/ops
  # ops is a nested table, completed as the script directory it's also laid out
  # as: the menu off the scripts in it, each one's arguments off its header.
  (test (offers? (hey "dispatch" "ops" "") "push-keys:Give SYSTEM") true)
  (test (dumped "ops" "push" "") "DUMP ops push")
  # hey ops edit takes SYSTEM:FILE rather than a bare SYSTEM, so it's the one
  # command in there with a completer of its own. The @ref in its header and the
  # function in _hey have to agree on a name, and nothing else notices when
  # they stop agreeing.
  (test (last (hey "dispatch" "ops" "edit" "")) "ARG *:target:__hey_edit_target")
  (test (hey "call" "__hey_edit_target" "") @["WANT[hosts] -S : -a hosts"])
  # Past the colon there's a whole other machine, so nothing.
  (test (hey "call" "__hey_edit_target" "box:") @[]))

(deftest completion/hook-areas
  # The menu carries the sigil, so areas and hooks can share it; past the
  # sigil, the areas are bare.
  (test (hey "areas" "") @["DESC[areas] @alpha @beta @host"])
  (test (hey "areas" "@") @["DESC[areas] alpha beta host"])
  # A consumed @AREA leaves the hook name to the rest arguments.
  (test (hey "hookarg" "@alpha") @["HOOKS alpha"])
  (test (hey "hookarg" "on-reload") @["DEFAULT"]))

(deftest completion/hooks
  # @AREA picks its dirs the way hook.janet's area-of does: the owner of a
  # hooks/ dir, host for hosts/*/hooks, NAME for a fragment's hooks.d/NAME.d.
  (test (hey "hooks" "alpha") @["SCAN config/alpha/hooks" "DESC[hooks] on-x:first on-y:third"])
  (test (first (hey "hooks" "host")) "SCAN hosts/testhost/hooks")
  (test (first (hey "hooks" "beta")) "SCAN test/_lib/data/hooks.d/beta.d")
  # Unscoped, every dir, and the areas share the menu.
  (test (hey "hooks")
        @["SCAN config/alpha/hooks hosts/testhost/hooks test/_lib/data/hooks.d/beta.d"
          "DESC[hooks] on-x:first on-y:third"
          "AREAS"]))

(deftest completion/paths-are-not-dot-commands
  (test (hey "dispatch" "./foo" "") @["DEFAULT"]))

(deftest completion/command-reconstruction
  # hey.comp.scriptdir has to rebuild the command line for `hey help --dump`. The
  # sigil belongs to the first word whether the NAME.d walk consumes it or it is
  # the leaf, and @DIR must keep its sigil while wm and host do not.
  (test (dumped ".nest" "deep" "") "DUMP .nest deep")
  (test (dumped "wm" "solo" "") "DUMP wm solo")
  (test (dumped "@alpha" "solo" "") "DUMP @alpha solo"))

(deftest completion/script-listing
  # The .NAME sigil lists the bin directories; @DIR the config directories.
  (test (hey "menu" ".") @["DESC[scripts] nest: solo:A fixture script."])
  (test (hey "menu" "@") @["WANT[directories] -a _hey_cfgdirs"]))

(deftest completion/a-matched-rule-is-an-answer
  # host, wm, @DIR and .NAME all consume $words[1] before they walk. A rule that
  # matched and came up empty must not fall through to "read its header", or hey
  # gets asked about whatever is left in $words[1] -- here, nothing at all.
  (test (hey "reconstruct" "host" "") @[]))

(deftest completion/degrades-without-hey
  (test (hey "nohey" "sync" "") @[])
  (test (hey "nohey" ".solo" "") @["DEFAULT"]))

(deftest completion/empty-word-is-not-a-bare-dump
  # `hey '' <TAB>` must not run a bare `hey help --dump`. The canary has to be a
  # command that still exists, or this passes by never finding anything.
  (def out (hey "dispatch" "" ""))
  (test (offers? out "sync:Rebuild this flake") false)
  # ...and the same word does come back from a dump that was asked for.
  (test (offers? (hey "menu" "") "sync:Rebuild this flake") true))

(deftest completion/wrapped-commands
  # `compdef NAME _hey` is the whole story for a `exec hey .NAME "$@"` wrapper
  # (like bin/lab): the menu is the wrapper's own script directory, and a
  # leaf's arguments are dumped through the sigil hey resolves it by.
  (test (hey "wrapper" "nest" "") @["DESC[scripts] deep:A nested fixture script."])
  (test (find |(string/has-prefix? "DUMP " $0) (hey "wrapper-dump" "nest" "deep" ""))
        "DUMP .nest deep"))

(deftest completion/cobra
  # @cobra asks the script itself for `__complete WORDS... PREFIX`, by path
  # rather than through hey, which would have eaten the -h. The colon in a
  # value has to be escaped for _describe; the one before a description not.
  (test (hey "cobra" "0" "run" "-h" "")
        @["DESC -t|cobra|argument|_hey_reply = image\\:tag:An image|argv\\:run,-h,"])
  # NoSpace
  (test (hey "cobra" "2" "run" "-h" "")
        @["DESC -t|cobra|argument|_hey_reply|-S| = image\\:tag:An image|argv\\:run,-h,"])
  # Error, and NoFileComp with nothing to offer, are both nothing; without
  # NoFileComp, nothing is zsh's to fill in.
  (test (hey "cobra" "1" "run" "") @[])
  (test (hey "cobra" "4empty" "run" "") @[])
  (test (hey "cobra" "0empty" "run" "") @["DEFAULT"])
  # It finds the script by the command line that reached it, which *:: has
  # sliced off $words by the time it runs.
  (test (hey "leaf" ".nest" "deep" "x" "") @["LEAF .nest deep"])
  (test (hey "leaf" "wm" "solo" "") @["LEAF wm solo"])
  # The wrapper tests can't reach bin/lab.d (they walk a fixture tree), so pin
  # the other end of the @ref here: lab docker, and its dk alias, ask for it.
  (each name [".lab docker" ".lab dk"]
    (def out ($<_ ,shim help --dump ,;(string/split " " name)))
    (test (last (string/split "\n" out)) "*::args:__hey_cobra")))
