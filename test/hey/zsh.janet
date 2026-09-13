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

# janet-sh routes a redirect into a buffer through file/temp, which always
# writes to /tmp. Capturing into hey's own runtime directory keeps these tests
# runnable where /tmp isn't writable; it's tmpfs, so it clears at logout.
(def- scratch-dir
  (let [dir (hey/path :runtime "temp")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    dir))
(def- out-file (hey/path/join scratch-dir "test-zsh.out"))
(def- err-file (hey/path/join scratch-dir "test-zsh.err"))

(deftest hey.requires
  (def null (file/open "/dev/null"))
  (test (zsh $? hey.requires zsh bash sh) true)
  (test (zsh $? hey.requires zsh bash doesnotexist > [stderr null]) false)
  (test (zsh $? hey.requires doesnotexist > [stderr null]) false))

(deftest hey.do
  (with [out (file/open out-file :w)]
    (zsh $ hey.do echo 10 > ,out))
  (test (string/trim (slurp out-file)) "10")

  (hey/with-envvars ["HEYDRYRUN" "1"]
    (with [out (file/open out-file :w)]
      (with [err (file/open err-file :w)]
        (zsh $ hey.do echo 10 > ,out > [stderr err])))
    (test (empty? (slurp err-file)) false)
    (test (empty? (slurp out-file)) true)))
