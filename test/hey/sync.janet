#!/usr/bin/env janet
# Regression tests for bin/hey.d/sync.janet.
#
# The rebuild belongs to nixos-rebuild and to a machine I'm willing to reboot.
# What's mine is the argument list it gets handed, so that's what's here.

(use judge)
(import hey)

# import drops private bindings; require doesn't. Reaching through it costs the
# same one line as an import would, and sync.janet keeps its surface to itself.
(def- image-args
  (get-in (require "../../bin/hey.d/sync") ['image-args :value]))
(def- cache-options-of
  (get-in (require "../../bin/hey.d/sync") ['cache-options-of :value]))

(defn- cache-options
  ``What sync would hand nixos-rebuild for a host whose nix.settings nix printed
  as TEXT -- or for one it couldn't evaluate at all, if TEXT is nil. nix here is
  sync.d/bin/nix, ahead of the real one.``
  [text]
  (hey/with-envvars ["PATH" (string (hey/path :test "hey/sync.d/bin") ":" (os/getenv "PATH"))
                     "HEY_TEST_NIX_SETTINGS" text]
    (cache-options-of "flake#nixosConfigurations.host")))


(deftest sync/cache-options
  (deftest "Each line nix prints is one --option, value kept whole"
    (test (cache-options
            (string "extra-substituters https://a.cachix.org https://b.cachix.org\n"
                    "extra-trusted-public-keys a.cachix.org-1:AAA= b.cachix.org-1:BBB="))
          @["--option" "extra-substituters" "https://a.cachix.org https://b.cachix.org"
            "--option" "extra-trusted-public-keys" "a.cachix.org-1:AAA= b.cachix.org-1:BBB="]))

  # The bare-with-a-space line sits in the middle because $<_ trims the tail
  # of what nix says, so as the last line it would never reach the parser.
  (deftest "A name with nothing after it is not an option"
    (test (cache-options (string "extra-substituters\n"
                                 "extra-substituters \n"
                                 "extra-trusted-public-keys a.cachix.org-1:AAA="))
          @["--option" "extra-trusted-public-keys" "a.cachix.org-1:AAA="]))

  (deftest "A flake that won't evaluate is a warning, not a dead sync"
    (test (cache-options nil) @[])))


(deftest sync/image-args
  # A bare variant becomes the flag nixos-rebuild wants; whatever follows it is
  # nixos-rebuild's and passes through. A flag is never a variant.
  (test (image-args ["iso" "--show-trace"]) ["--image-variant" "iso" "--show-trace"])
  (test (image-args ["--show-trace"]) ["--show-trace"]))
