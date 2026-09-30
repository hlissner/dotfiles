#!/usr/bin/env janet
# Regression tests for bin/hey.d/sync.janet.
#
# The rebuild belongs to nixos-rebuild and to a machine I'm willing to reboot.
# What's mine is the argument list it gets handed, so that's what's here.

(use judge)
(import hey)
(use sh)

# import drops private bindings; require doesn't. Reaching through it costs the
# same one line as an import would, and sync.janet keeps its surface to itself.
(def- image-args
  (get-in (require "../../bin/hey.d/sync") ['image-args :value]))

(deftest sync/image-args
  # A bare variant becomes the flag nixos-rebuild wants; whatever follows it is
  # nixos-rebuild's and passes through. A flag is never a variant.
  (test (image-args ["iso" "--show-trace"]) ["--image-variant" "iso" "--show-trace"])
  (test (image-args ["--show-trace"]) ["--show-trace"]))

# `hey sync links` is a unit start and a journal replay; sudo, systemctl and
# journalctl are stubs (sync.d/bin) that log what they were asked.
(def- bin (hey/path :home "bin/hey"))
(def- stubs (hey/path :test "hey/sync.d/bin"))
(def- log
  (let [dir (hey/path :runtime "test.d")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    (hey/path/join dir (string "sync-" (os/getpid) ".log"))))

(defn- links
  "Run `hey sync links`, the unit exiting with CODE. [exit-code output calls]."
  [code]
  (spit log "")
  (def out @"")
  (def status
    (hey/with-envvars ["XDG_BIN_HOME" stubs
                       "HEY_TEST_SYNC_LOG" log
                       "HEY_TEST_UNIT_EXIT" (string code)]
      (first (run ,bin sync links > ,out > [stderr out]))))
  [status (string/trim (string out))
   (filter |(not (empty? $0)) (string/split "\n" (string (slurp log))))])

(deftest sync/links
  (test (links 0)
    [0
     "replayed"
     @["sudo systemctl start hey-home-links.service"
       "systemctl start hey-home-links.service"
       "systemctl show -p InvocationID --value hey-home-links.service"
       "journalctl -q -a -o cat _SYSTEMD_INVOCATION_ID=0123456789abcdef0123456789abcdef"]])
  # A failed unit still gets replayed -- that's where the reason is -- and
  # fails the command.
  (def [status out calls] (links 1))
  (test status 1)
  (test out "replayed")
  (test (length calls) 4))
