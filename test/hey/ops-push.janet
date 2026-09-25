#!/usr/bin/env janet
# Regression tests for bin/hey.d/ops.d/push.janet.
#
# ssh and nixos-rebuild are stubs (ops-push.d/bin/*): the first only has to pass
# the probe, the second echoes what it was asked for. What's left to pin is
# which config gets built, since SYSTEM is an ssh destination and rarely a host.

(use judge)
(use sh)
(import hey)

(def- bin (hey/path :home "bin/hey"))
(def- stubs (hey/path :test "hey/ops-push.d/bin"))
(def- workstation (hey/path :test "hey/ops.d/workstation"))

(defn- push
  "Run `hey ops push ARGS`, and return [exit-code flake target action host]."
  [& args]
  (def out @"")
  (def code
    (hey/with-envvars ["XDG_DATA_HOME" workstation
                       "XDG_BIN_HOME" stubs]
      (first (run ,bin ops push ,;args > ,out > [stderr :null]))))
  (def lines (string/split "\n" (string/trim out)))
  (def argv (string/split " " (first lines)))
  (def after |(get argv (inc (or (index-of $0 argv) -2))))
  [code
   (when-let [f (after "--flake")] (last (string/split "#" f)))
   (after "--target-host")
   (first argv)
   (get lines 1)])


(deftest push/system-is-the-host
  (test (push "ramen") [0 "ramen" "ramen" "switch" "HEYENV.host=ramen"]))

(deftest push/system-is-not-the-host
  # The reason HOST exists: ssh goes to ramen.lan, but it's ramen that gets built.
  (test (push "ramen.lan" "ramen")
        [0 "ramen" "ramen.lan" "switch" "HEYENV.host=ramen"])
  (test (push "10.0.0.2" "ramen" "boot")
        [0 "ramen" "10.0.0.2" "boot" "HEYENV.host=ramen"]))

(deftest push/action-is-not-a-host
  # No hosts/boot, so boot is nixos-rebuild's, not a HOST.
  (test (push "soba" "boot") [0 "soba" "soba" "boot" "HEYENV.host=soba"]))

(deftest push/no-such-host
  # Rather than build a config that doesn't exist, or worse, one that does and
  # isn't SYSTEM's.
  (test (first (push "ramen.lan")) 127)
  (test (first (push "ramen.lan" "boot")) 127))
