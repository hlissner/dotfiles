#!/usr/bin/env janet
# The pure half of bin/hey.d/hook.janet's area handling. Resolution itself
# reads config/, so it's left to `hey hook -l`.

(use judge)
(import hey)

# import drops private bindings; require doesn't. Going through it for all of
# these, public or not, leaves hook.janet free to change its mind about which is
# which without any of it reaching the tests.
(def- env (require "../../bin/hey.d/hook"))
(defn- fn-of [name] (get-in env [name :value]))
(def- ls (fn-of 'ls))
(def- parse-area (fn-of 'parse-area))
(def- sort-areas (fn-of 'sort-areas))

(def- scratch
  (let [dir (hey/path :runtime "test.d" (string "hook-" (os/getpid)))]
    (os/mkdir (hey/path :runtime))
    (os/mkdir (hey/path :runtime "test.d"))
    (os/mkdir dir)
    dir))

(defn- touch-all [dir & names]
  (each name names
    (with [f (file/open (hey/path/join dir name) :w)] (:write f ""))))


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

(deftest hook/sort-areas
  # The window manager runs first, the rest alphabetically, and host is always
  # last, known, and never twice.
  (test (sort-areas ["host" "zsh" "hypr" "git"] "hypr") ["hypr" "git" "zsh" "host"])
  # An absent or unset window manager forfeits its slot.
  (test (sort-areas ["zsh" "git"] nil) ["git" "zsh" "host"]))
