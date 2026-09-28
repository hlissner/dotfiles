#!/usr/bin/env janet
# bin/hey.d/hook.janet's resolution, minus hey.info.hooks: handlers takes the
# directories as an argument, so these feed it scratch ones.

(use judge)
(use sh)
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

# Wiped first: the sandbox recycles pids, and a file left over from another run
# keeps its old mode however many times it's reopened.
(def- scratch
  (let [dir (hey/path :runtime "test.d" (string "hook-" (os/getpid)))]
    ($ rm -rf ,dir)
    ($ mkdir -p ,dir)
    dir))

(defn- mkdir [name]
  (let [dir (hey/path/join scratch name)]
    (os/mkdir dir)
    dir))

(defn- touch [dir mode & names]
  (each name names
    (let [file (hey/path/join dir name)]
      (spit file "")
      (os/chmod file mode))))


(deftest hook/ls
  # Deliberately out of order, and enough of them that no filesystem is going
  # to hand them back sorted by accident. The NN- prefixes mean nothing without
  # this.
  (let [dir (mkdir "ls")]
    (touch dir 8r644 "90-z" "10-a" "50-m" "20-b" "05-q")
    (test (ls dir) @["05-q" "10-a" "20-b" "50-m" "90-z"]))
  # A directory that isn't there is no handlers, not an error.
  (test (ls (hey/path/join scratch "nope")) @[]))

(deftest hook/parse-area
  # A leading sigil scopes the hook and shifts everything down one; without
  # one, the arguments pass through untouched.
  (test (parse-area "@zsh" ["on-reload" "--now"]) ["zsh" "on-reload" ["--now"]])
  (test (parse-area "on-reload" ["--now"]) [nil "on-reload" ["--now"]]))

(deftest hook/hook-name+order
  # NN- and the extension are both optional, and neither is part of the name.
  # Unnumbered sits at 50, the same default modules/hey.nix gives fragments.
  (test (map |[(hook-name $0) (order $0)]
             ["20-on-x.janet" "05-on-x" "on-x.zsh" "on-f2-pressed.sh" "on-x.bak"])
        @[["on-x" 20]
          ["on-x" 5]
          ["on-x" 50]
          ["on-f2-pressed" 50]
          ["on-x.bak" 50]]))

(deftest hook/area-of
  (test (area-of "/home/me/dotfiles/config/zsh/hooks") "zsh")
  (test (area-of "/home/me/dotfiles/hosts/udon/hooks/") "host")
  (test (area-of "/home/me/.local/share/hey/hooks.d/power-profile.d") "power-profile"))

(deftest hook/handlers
  # One flat list across every directory, by NN-. A tie goes to whichever
  # directory was listed first, which is why z comes before a: alphabetical
  # would pass by accident.
  (let [z (mkdir "z") a (mkdir "a")]
    (touch z 8r755 "20-on-x.zsh" "on-x.zsh" "on-y.zsh")
    (touch z 8r644 "10-on-x.zsh")  # not executable, so not a handler
    (touch a 8r755 "10-on-x.janet" "on-x")
    (test (map |(string/slice $0 (inc (length scratch))) (handlers [z a] "on-x"))
          @["a/10-on-x.janet" "z/20-on-x.zsh" "z/on-x.zsh" "a/on-x"])
    # An absent directory (an area with no hooks/ yet) is just empty.
    (test (handlers [(hey/path/join scratch "nope")] "on-x") @[])))
