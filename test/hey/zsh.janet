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

# wm.d's noctalia and notify-send stand-ins, which log their argv.
(def- stubs (hey/path :test "hey/wm.d/bin"))
(def- stub-log
  (let [dir (hey/path :runtime "test.d")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    (hey/path/join dir (string "zsh-" (os/getpid) ".log"))))

(defn- sent
  ``What the stubs logged for `hey.FN ARGS`, as one trimmed string.``
  [fn & args]
  (spit stub-log "")
  (hey/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH"))
                     "HEY_TEST_WM_LOG" stub-log]
    ($? zsh -c ,autoload-hey "hey-test" ,fn ,;args))
  (string/trim (slurp stub-log)))

(deftest hey.toast
  # jq keeps insertion order, so the whole payload is fair game here.
  (test (sent "hey.toast" "warn" "hi")
        `noctalia msg osd-show {"icon":"alert-triangle","value":"hi"}`)
  (test (sent "hey.toast" "-i" "moon" "-p" "0.5" "-m" "info" "x")
        `noctalia msg osd-show {"icon":"moon","value":"x","progress":0.5,"inactive":true}`))

(deftest hey.notify
  (test (sent "hey.notify" "error" "Title" "Body")
        "notify-send -a hey -u critical -- Title Body")
  (test (sent "hey.notify" "-a" "App" "-i" "/tmp/x.png" "info" "T")
        "notify-send -a App -u normal -i /tmp/x.png -- T")
  # A box with notify-send but no shell to show it: nothing, not a hang.
  (def bare (hey/path/join (hey/path :runtime "test.d") (string "zsh-" (os/getpid) ".bin")))
  (os/mkdir bare)
  (os/symlink (hey/path/find "zsh") (hey/path/join bare "zsh"))
  (os/symlink (hey/path/join stubs "notify-send") (hey/path/join bare "notify-send"))
  (test (hey/with-envvars ["PATH" bare "HEY_TEST_WM_LOG" stub-log]
          (zsh $? hey.notify info x > [stderr :null]))
        false))

(deftest hey.do
  (test (zsh $<_ hey.do echo 10) "10")

  # A dry run says what it would do on stderr and does nothing on stdout.
  (hey/with-envvars ["HEYDRYRUN" "1"]
    (def err @"")
    (test (zsh $< hey.do echo 10 > [stderr err]) "")
    (test (empty? err) false)))
