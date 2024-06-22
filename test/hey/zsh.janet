#!/usr/bin/env janet

(use judge)
(use sh)
(import hey)

(defmacro zsh [& args]
  ~(,(first args) zsh ,(hey/path :lib "zsh" (get args 1)) ,;(slice args 2)))

(def- null (file/open "/dev/null"))

(deftest hey.requires
  (test (zsh $? hey.requires zsh bash sh) true)
  (test (zsh $? hey.requires zsh bash doesnotexist > [stderr null]) false)
  (test (zsh $? hey.requires doesnotexist > [stderr null]) false))

(deftest hey.do
  (test (zsh $<_ hey.do echo 10) "10")
  (hey/with-envvars ["HEYDRYRUN" "1"]
    (let [out @"" err @""]
      (zsh $<_ hey.do echo 10 > ,out > [stderr err])
      (test (deep-not= err @"") true)
      (test out @""))))
