#!/usr/bin/env janet
# Regression tests for lib/hey/rbw.janet and bin/hey.d/bw.janet.
#
# rbw is a shell script (rbw.d/bin/rbw) that writes down which runtime dir it
# was run under -- which is to say, which agent it would've talked to. Whether
# the real rbw can unlock a vault is rbw's problem; that the agent is private
# and never outlives the block is mine.

(use judge)
(use sh)
(import hey)
(import hey/rbw)

(def- bin (hey/path :home "bin/hey"))
(def- stubs (hey/path :test "hey/rbw.d/bin"))

# The pid is in the name because judge runs the suites side by side.
(def- log
  (let [dir (hey/path :runtime "test.d")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    (hey/path/join dir (string "rbw-" (os/getpid) ".log"))))

(defn- calls
  "Every rbw invocation since the last reset, as [RUNTIME-DIR DISPLAY ARGS]."
  []
  (seq [line :in (string/split "\n" (slurp log))
        :unless (empty? line)]
    (tuple ;(string/split "\t" line))))

(defn- vault
  ``Run F in with-vault*, rbw stubbed, and return what F saw: the runtime dir
  and display, whether that dir existed, and F's result or error.``
  [f &named display]
  (spit log "")
  (def seen @{})
  (hey/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH"))
                     "WAYLAND_DISPLAY" (or display "wayland-9")
                     "HEY_TEST_RBW_LOG" log]
    (put seen :result
         (protect (rbw/with-vault*
                   (fn []
                     (put seen :dir (os/getenv "XDG_RUNTIME_DIR"))
                     (put seen :display (os/getenv "WAYLAND_DISPLAY"))
                     (put seen :exists? (hey/path/directory? (seen :dir)))
                     (f))))))
  seen)


(deftest rbw/private-agent
  (def seen (vault |($ rbw get foo)))
  (def dir (seen :dir))
  (test (seen :result) [true nil])
  # A fresh dir of its own, not the session's runtime dir...
  (test (seen :exists?) true)
  (test (string/has-prefix? (hey/path :runtime "rbw.") dir) true)
  # ...that doesn't outlive the block, and neither does its agent.
  (test (hey/path/exists? dir) false)
  (test (all |(= dir (first $0)) (calls)) true)
  (test (map last (calls)) @["get foo" "stop-agent"])
  # And the caller gets its environment back.
  (test (= (os/getenv "XDG_RUNTIME_DIR") (hey/path/xdg :runtime)) true))

(deftest rbw/stops-on-error
  (def seen (vault |(error "boom")))
  (test (seen :result) [false "boom"])
  (test (hey/path/exists? (seen :dir)) false)
  (test (map last (calls)) @["stop-agent"]))

(deftest rbw/wayland-display
  # Relative, it'd resolve against the private runtime dir, where no
  # compositor lives, and pinentry-rofi would have nowhere to draw.
  (test (= ((vault |nil) :display) (hey/path/xdg :runtime "wayland-9")) true)
  (test ((vault |nil :display "/run/wl-0") :display) "/run/wl-0"))

(deftest bw/passthrough
  (spit log "")
  (def code
    (hey/with-envvars ["XDG_BIN_HOME" stubs
                       "HEY_TEST_RBW_LOG" log
                       "HEY_TEST_RBW_EXIT" "3"]
      (first (run ,bin bw get -f username foo > [stderr :null]))))
  (test code 3)
  (test (map last (calls)) @["get -f username foo" "stop-agent"]))


## The session-agent API. Same stub, now with lines to say.

(defn- stubbed
  "F with rbw stubbed to print OUT and exit EXIT."
  [f &named out exit]
  (spit log "")
  (hey/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH"))
                     "HEY_TEST_RBW_LOG" log
                     "HEY_TEST_RBW_OUT" out
                     "HEY_TEST_RBW_EXIT" (if exit (string exit))]
    (f)))

(deftest rbw/lock-state
  (test (stubbed rbw/unlocked?) true)
  (test (stubbed rbw/unlocked? :exit 1) false)
  (test (map last (calls)) @["unlocked"])
  (test (stubbed rbw/lock) true)
  (test (stubbed rbw/unlock :exit 1) false))

(deftest rbw/items
  (def items
    (stubbed rbw/items
             :out `[{"id":"a","name":"GitHub","user":"me","folder":null,"uris":["https://github.com"],"type":"Login"},
                    {"id":"b","name":"laptop","user":null,"folder":"keys","uris":null,"type":"SSH Key"},
                    {"id":"c","name":"Recovery","user":null,"folder":null,"uris":null,"type":"Note"},
                    {"id":"d","name":"??","user":null,"folder":null,"uris":null,"type":"Hologram"}]`))
  (test (map last (calls)) @["list --raw"])
  (test (map |($0 :type) items) @[:login :sshkey :note :unknown])
  # Nulls are kept as :null, so a caller can tell "absent" from "unset".
  (test (get-in items [1 :user]) :null))

(deftest rbw/entry
  (def e (stubbed |(rbw/entry "a")
                  :out `{"id":"a","folder":null,"name":"GitHub","data":{"username":"me","password":"hunter2","totp":null,"uris":[{"uri":"https://github.com","match_type":null}]},"fields":[{"name":"pin","value":"1234","type":"hidden"}],"notes":null,"history":[]}`))
  (test (map last (calls)) @["get --raw a"])
  (test (e :type) :login)
  (test (get-in e [:fields 0 :type]) "hidden"))

(deftest rbw/type-of
  (test (rbw/type-of {:data {:password :null :username "x"}}) :login)
  (test (rbw/type-of {:data {:number "4111" :brand :null}}) :card)
  (test (rbw/type-of {:data {:first_name :null}}) :identity)
  (test (rbw/type-of {:data {:private_key "k"}}) :sshkey)
  # A secure note's data is an empty object, not null.
  (test (rbw/type-of {:data {}}) :note)
  (test (rbw/type-of {}) :note))

(deftest rbw/code
  (test (stubbed |(rbw/code "a") :out "123456") "123456")
  (test (stubbed |(rbw/code "a") :exit 1) nil)
  (test (map last (calls)) @["code a"]))

(deftest rbw/generators
  (test (rbw/format-passphrase ["foo" "bar" "baz" "woff"] 2 0) "Foo-Bar-Baz0-Woff")
  (test (rbw/format-passphrase ["foo"] 0 7) "Foo7")

  (test (stubbed rbw/password :out "C6oCmgZHVoEZr4eyWzGC14gXGC5WwhV4") "C6oCmgZHVoEZr4eyWzGC14gXGC5WwhV4")
  (test (map last (calls)) @["generate --no-symbols 32"])

  (def phrase (stubbed rbw/passphrase :out "avalanche author immortal agreeing parsley"))
  (test (map last (calls)) @["generate --diceware 5"])
  # Five capitalized words, dashes between, exactly one digit somewhere.
  (test (truthy? (peg/match ~(* (5 (* (range "AZ") (some (range "az")) (? (range "09")) (? "-"))) -1) phrase)) true)
  (test (length (filter |(and (>= $0 48) (<= $0 57)) (string/bytes phrase))) 1)
  (test (string/split "-" (string/replace-all "0" "" (peg/replace-all ~(range "09") "" phrase)))
        @["Avalanche" "Author" "Immortal" "Agreeing" "Parsley"])

  (def user (stubbed rbw/username :out "trodden"))
  (test (map last (calls)) @["generate --diceware 1"])
  (test (truthy? (peg/match ~(* "Trodden" (4 (range "09")) -1) user)) true)

  (test (stubbed |(rbw/email "login.henrik.io") :out "AbC12xYz") "abc12xyz@login.henrik.io")
  (test (map last (calls)) @["generate --no-symbols 8"]))
