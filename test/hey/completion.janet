#!/usr/bin/env janet
# Regression tests for lib/zsh/completions/_hey, and for the hey.comp.*
# functions in lib/zsh it shares with _heyops.
#
# Everything here fails silently in real life: a broken completion offers
# nothing, and TAB just doesn't do anything.

(use judge)
(import ./../_lib/completion :prefix "")

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

(deftest completion/hook-areas
  # The menu carries the sigil, so areas and hooks can share it; past the
  # sigil, the areas are bare.
  (test (hey "areas" "") @["DESC[areas] @alpha @beta @host"])
  (test (hey "areas" "@") @["DESC[areas] alpha beta host"])
  # A consumed @AREA leaves the hook name to the rest arguments.
  (test (hey "hookarg" "@alpha") @["HOOKS alpha"])
  (test (hey "hookarg" "on-reload") @["DEFAULT"]))

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
