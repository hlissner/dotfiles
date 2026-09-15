#!/usr/bin/env janet

(use judge)
(use hey)
(use sh)
(import hey/vars)
(import spork/path)

(def- vars (vars/new (:dir (vars/temp) :test)))
(def- hey-bin
  (path/abspath (path/join (path/dirname (dyn :current-file)) "../../bin/hey")))

(defn- setup []
  ($ rm -rf ,(:dir vars)))  # Always start from scratch

(deftest get/set
  (setup)
  (test (:get vars :does-not-exist) nil)
  # The key, not the value, whether it wrote or removed -- so that nothing can
  # come to depend on the value being handed back (config/hypr/bin/slurp.zsh
  # used to print it as its own output).
  (test (:set vars :key 123) :key)
  (test (:get vars :key) 123)
  (test (:set vars :key nil) :key))

(deftest list
  (setup)
  # os/dir throws on a directory that was never created, and nothing creates it
  # until the first :set -- so `hey vars` used to crash on a fresh machine.
  (test (:list vars) @[])
  (:set vars :foo 1)
  (:set vars :bar 2)
  (test (length (:list vars)) 2)
  (:clear vars)
  (test (:list vars) @[]))

# Keys are filenames. A key that climbs out of the store writes somewhere :list
# and :clear can't see it, which is how you lose track of state.
(deftest keys/rejected
  (setup)
  (each bad ["../escaped" "a/b" `a\b` "." ".." ""]
    (test (true? (nil? (ignore-errors (:set vars bad 1)))) true))
  (test (:list vars) @[])
  # Dots are only a problem when they're the whole name.
  (test (:set vars :hypr.slurp.last 1) :hypr.slurp.last))

(deftest cache
  (setup)
  (var calls 0)
  (defn- count! [val] (fn [] (++ calls) val))

  (deftest "Computes once, then reads back"
    (test (:cache vars :n (count! 42)) 42)
    (test (:cache vars :n (count! 42)) 42)
    (test calls 1))

  # `or` treated a cached false as a miss, so valfn ran on every call.
  (deftest "false is a value, not a cache miss"
    (set calls 0)
    (test (:cache vars :f (count! false)) false)
    (test (:cache vars :f (count! false)) false)
    (test calls 1)))

# `hey get` is read in shell scripts as a test, not just for its output --
# config/hypr/bin/slurp.zsh does `if ! hey get $cache_key`. Printing nothing and
# exiting 0 made "unset" indistinguishable from "set to an empty string", so the
# retake path silently produced an empty region instead of erroring.
(deftest get/exit-status
  (setup)
  # /dev/null, or the var's value lands in the suite's own output.
  (def devnull (file/open "/dev/null" :w))
  (defn- hey-get [name]
    (os/execute [hey-bin "get" (string name)] :p {:out devnull}))

  (:set (vars/temp) :exit-status-empty "")
  (test (hey-get :nope) 1)
  # An empty string is a value, not an absence.
  (test (hey-get :exit-status-empty) 0)
  (:set (vars/temp) :exit-status-empty nil))

# `set` echoes the key, so a caller that wants to store and print in one go
# needs -v. config/hypr/bin/slurp.zsh is that caller: the selection it caches is
# also its own stdout, which screencast.zsh parses as "X,Y WxH".
(deftest set/echoes
  (setup)
  (defn- hey-out [& args] ($<_ ,hey-bin ,;args))

  (test (hey-out "set" "echoes-test" "X,Y WxH") "echoes-test")
  (test (hey-out "set" "-v" "echoes-test" "X,Y WxH") "X,Y WxH")

  (:set (vars/temp) :echoes-test nil))
