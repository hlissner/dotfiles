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

(deftest sync/image-args
  # A bare variant becomes the flag nixos-rebuild wants; whatever follows it is
  # nixos-rebuild's and passes through. A flag is never a variant.
  (test (image-args ["iso" "--show-trace"]) ["--image-variant" "iso" "--show-trace"])
  (test (image-args ["--show-trace"]) ["--show-trace"]))
