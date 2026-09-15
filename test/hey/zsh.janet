#!/usr/bin/env janet

(use judge)
(use sh)
(import hey)

# Ensure zsh helpers are available to these tests.
(def- autoload-hey
  (let [dir (hey/path :lib "zsh")]
    (string "fpath=( " dir " ); autoload -Uz ${fpath[1]}/hey.*(.:t); \"$@\"")))

(defmacro zsh [& args]
  ~(,(first args) zsh -c ,autoload-hey "hey-test"
    ,(string (get args 1)) ,;(slice args 2)))

(deftest hey.requires
  (test (zsh $? hey.requires zsh bash sh) true)
  (test (zsh $? hey.requires zsh bash doesnotexist > [stderr :null]) false))

(deftest hey.do
  (test (zsh $<_ hey.do echo 10) "10")

  # A dry run says what it would do on stderr and does nothing on stdout.
  (hey/with-envvars ["HEYDRYRUN" "1"]
    (def err @"")
    (test (zsh $< hey.do echo 10 > [stderr err]) "")
    (test (empty? err) false)))
