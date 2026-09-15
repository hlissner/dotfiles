#!/usr/bin/env janet
# Regression tests for lib/hey/ops.janet.
#
# probe and check are one ssh round trip each, so they belong to a machine I can
# actually reach, not to a test suite. What's left is the two functions that
# decide what those round trips say.

(use judge)
(import spork/json)
(import hey)
(import hey/ops)


(deftest ops/ssh-dir
  # modules.xdg.ssh moves ~/.ssh out from under itself, and only workstations
  # turn it on. Expanded by the remote shell, so these stay literal.
  (test (map ops/ssh-dir ["workstation" "server" nil])
        @["$HOME/.config/ssh" "$HOME/.ssh" "$HOME/.ssh"]))

(deftest ops/heyenv
  # What lib/nixos.nix reads back. hey.dir comes out of `path`, so pointing it
  # at the store would be a bad day; the only thing changing is the host.
  (def env (json/decode (ops/heyenv "somehost")))
  (test (get env "host") "somehost")
  # Compared rather than pinned: this is this machine's, and judge only wants
  # literals on the right.
  (test (= (get env "path") (hey/path :home)) true))
