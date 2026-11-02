#!/usr/bin/env janet
# Regression tests for bin/hey.d/ops.d/push.janet.
#
# ssh, rsync and nixos-rebuild are stubs (ops-push.d/bin/*): the first only has
# to pass the probe, the other two echo what they were asked for. What's left
# to pin is which config gets built, since SYSTEM is an ssh destination and
# rarely a host, and that the checkout lands on SYSTEM before anything builds.

(use judge)
(use sh)
(import hey)

(def- bin (hey/path :home "bin/hey"))
(def- stubs (hey/path :test "hey/ops-push.d/bin"))
(def- workstation (hey/path :test "hey/ops.d/workstation"))

(defn- push
  ``Run `hey ops push ARGS`, and return [exit-code flake target action dest]:
  the last is where rsync was sent, nil if it didn't run first.``
  [& args]
  (def out @"")
  (def code
    (hey/with-envvars ["XDG_DATA_HOME" workstation
                       "XDG_BIN_HOME" stubs]
      (first (run ,bin ops push ,;args > ,out > [stderr :null]))))
  (def [sync rebuild] (string/split "\n" (string/trim out)))
  (def argv (string/split " " (or rebuild "")))
  (def after |(get argv (inc (or (index-of $0 argv) -2))))
  [code
   (when-let [f (after "--flake")] (last (string/split "#" f)))
   (after "--target-host")
   (first argv)
   (when (and sync (string/has-prefix? "rsync " sync))
     (last (string/split " " sync)))])


(deftest push/system-is-the-host
  (test (push "ramen") [0 "ramen" "ramen" "switch" "ramen:/etc/dotfiles/"]))

(deftest push/system-is-not-the-host
  # The reason HOST exists: ssh goes to ramen.lan, but it's ramen that gets built.
  (test (push "ramen.lan" "ramen")
        [0 "ramen" "ramen.lan" "switch" "ramen.lan:/etc/dotfiles/"])
  (test (push "10.0.0.2" "ramen" "boot")
        [0 "ramen" "10.0.0.2" "boot" "10.0.0.2:/etc/dotfiles/"]))

(deftest push/action-is-not-a-host
  # No hosts/boot, so boot is nixos-rebuild's, not a HOST.
  (test (push "soba" "boot") [0 "soba" "soba" "boot" "soba:/etc/dotfiles/"]))

(deftest push/no-such-host
  # Rather than build a config that doesn't exist, or worse, one that does and
  # isn't SYSTEM's.
  (test (first (push "ramen.lan")) 127)
  (test (first (push "ramen.lan" "boot")) 127))

(deftest push/dotfiles-only
  # rsync and stop: no nixos-rebuild, so the first line is all there is. HOST
  # doesn't have to exist either, since nothing gets built.
  (test (push "ramen" "--dotfiles") [0 nil nil "" "ramen:/etc/dotfiles/"])
  (test (push "ramen.lan" "--dotfiles") [0 nil nil "" "ramen.lan:/etc/dotfiles/"])
  # ARGS would go to a nixos-rebuild that never runs.
  (test (first (push "ramen" "--dotfiles" "boot")) 127)
  (test (first (push "ramen" "--dotfiles" "-l")) 127))
