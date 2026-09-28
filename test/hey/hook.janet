#!/usr/bin/env janet
# bin/hey.d/hook.janet's resolution, minus hey.info.hooks: handlers takes the
# directories as an argument, so these feed it scratch ones.

(use judge)
(import hey)

# import drops private bindings; require doesn't. Going through it for all of
# these, public or not, leaves hook.janet free to change its mind about which is
# which without any of it reaching the tests.
(def- env (require "../../bin/hey.d/hook"))
(defn- fn-of [name] (get-in env [name :value]))
(def- ls (fn-of 'ls))
(def- parse-area (fn-of 'parse-area))
(def- hook-name (fn-of 'hook-name))
(def- order (fn-of 'order))
(def- area-of (fn-of 'area-of))
(def- handlers (fn-of 'handlers))

(def- scratch
  (let [dir (hey/path :runtime "test.d" (string "hook-" (os/getpid)))]
    (os/mkdir (hey/path :runtime))
    (os/mkdir (hey/path :runtime "test.d"))
    (os/mkdir dir)
    dir))

(defn- touch-all [dir & names]
  (each name names
    (with [f (file/open (hey/path/join dir name) :w)] (:write f ""))))

# Beside scratch, not in it, or hook/ls would see these too.
(defn- subdir [name]
  (let [dir (string scratch "-" name)]
    (os/mkdir dir)
    dir))

(defn- touch-x [dir & names]
  (touch-all dir ;names)
  (each name names (os/chmod (hey/path/join dir name) 8r755)))


(deftest hook/ls
  # Deliberately out of order, and enough of them that no filesystem is going
  # to hand them back sorted by accident. The NN- prefixes in modules/hey.nix's
  # generated hooks mean nothing without this.
  (touch-all scratch "90-z" "10-a" "50-m" "20-b" "05-q")
  (test (ls scratch) @["05-q" "10-a" "20-b" "50-m" "90-z"])
  # A directory that isn't there is no handlers, not an error.
  (test (ls (hey/path/join scratch "nope")) @[]))

(deftest hook/parse-area
  # A leading sigil scopes the hook and shifts everything down one; without
  # one, the arguments pass through untouched.
  (test (parse-area "@zsh" ["on-reload" "--now"]) ["zsh" "on-reload" ["--now"]])
  (test (parse-area "on-reload" ["--now"]) [nil "on-reload" ["--now"]]))

(deftest hook/hook-name
  # NN- and the extension are both optional, and neither is part of the name.
  (test (map hook-name ["20-on-x.janet" "on-x.zsh" "on-x" "05-on-x"])
        @["on-x" "on-x" "on-x" "on-x"])
  # A hook whose name merely has digits in it keeps them.
  (test (hook-name "on-f2-pressed.sh") "on-f2-pressed"))

(deftest hook/order
  # Unnumbered sits at 50, the same default modules/hey.nix gives fragments.
  (test (map order ["20-on-x.janet" "on-x.zsh" "05-on-x"]) @[20 50 5]))

(deftest hook/area-of
  (test (area-of "/home/me/dotfiles/config/zsh/hooks") "zsh")
  (test (area-of "/home/me/dotfiles/hosts/udon/hooks/") "host")
  (test (area-of "/home/me/.local/share/hey/hooks.d/power-profile.d") "power-profile"))

(deftest hook/handlers
  # One flat list across every directory, by NN-; a tie goes to whichever
  # directory came first. Non-executables and other hooks aren't handlers.
  (let [a (subdir "a") b (subdir "b")]
    (touch-x a "20-on-x.zsh" "on-x.zsh" "on-y.zsh")
    (touch-all a "10-on-x.zsh")
    (touch-x b "10-on-x.janet" "on-x")
    (test (map |(string/replace (string scratch "-") "" $0) (handlers [a b] "on-x"))
          @["b/10-on-x.janet" "a/20-on-x.zsh" "a/on-x.zsh" "b/on-x"])
    # An absent directory (an area with no hooks/ yet) is just empty.
    (test (handlers [(hey/path/join scratch "nope")] "on-x") @[])))
