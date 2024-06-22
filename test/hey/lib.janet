#!/usr/bin/env janet

(use judge)
(use hey)

(deftest atom?
  (test (all atom? [true false 0 1 1.5 "string" :keyword 'symbol])
        true)
  (test (all |(not (atom? $))
             [[1 2 3] @[1 2 3] {:foo 1 :bar 2} @{:foo 1 :bar 2} (fn (&)) atom?])
        true))

(deftest array/remove-elt
  (let [values @[1 2 3]]
    (test (array/remove-elt values 3) @[1 2])
    (test (array/remove-elt values 1) @[2])
    (test values @[2])))

(deftest macros
  (deftest with-envvars
    (test (os/getenv "TEST") nil)
    (with-envvars ["TEST" "123"]
      (test (os/getenv "TEST") "123")
      (os/setenv "TEST" "321")
      (test (os/getenv "TEST") "321"))
    (test (os/getenv "TEST") nil))

  # TODO (deftest with-umask)
  )

(deftest string
  (deftest chomp
    (test (string/chomp "foo") "foo")
    (test (string/chomp "foo\n") "foo")
    (test (string/chomp "foo\nbar\n\nbaz") "foo\nbar\n\nbaz"))

  # TODO (deftest no-suffix)
  # TODO (deftest no-prefix)
  )

(deftest path
  (deftest find
    (test (truthy? (path/find "janet")) true)
    (test (path/find "janet" []) nil)
    (test (path/find "does-not-exist") nil))

  # TODO (deftest sibling)
  # TODO (deftest files-in)
  # TODO (deftest abbrev)
  )
