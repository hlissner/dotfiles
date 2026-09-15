#!/usr/bin/env janet
# Regression tests for lib/zsh/completions/_heyops.
#
# Short on purpose. _heyops is the hey.comp.* functions in lib/zsh and nothing
# else, and test/hey/completion.janet already puts those through their paces.
# What's left is what's true of _heyops and of nothing else.

(use judge)
(import ./../_lib/completion :prefix "")

(defn- heyops [case & words] (complete "heyops" case ;words))


(deftest completion/globals-come-from-hey
  # heyops has no rule for "dump the header at this path", so _heyops asks hey
  # for heyops' own flags. If that ever stops working they vanish silently.
  (test (offers? (heyops "top" "") "-![Do a dry run") true))

(deftest completion/edit-targets
  # heyops edit takes SYSTEM:FILE rather than a bare SYSTEM, so it's the one
  # command here with a completer of its own. The @ref in its header and the
  # function in _heyops have to agree on a name, and nothing else notices when
  # they stop agreeing.
  (test (last (heyops "dispatch" "edit" "")) "ARG *:target:__hey_edit_target")
  (test (heyops "call" "__hey_edit_target" "") @["WANT[hosts] -S : -a hosts"])
  # Past the colon there's a whole other machine, so nothing.
  (test (heyops "call" "__hey_edit_target" "box:") @[]))

(deftest completion/no-dynamic-dispatch
  # hey grows its menu with .script and @configdir because it hands the shared
  # menu a set of search paths. heyops hands it none, dispatches to keywords
  # and nothing else, and must leave a sigil alone rather than start walking
  # directories.
  (test (deep= (heyops "menu" ".") (heyops "menu" "")) true))
