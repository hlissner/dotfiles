#!/usr/bin/env janet
# Regression tests for bin/lab.d/docker.zsh, against a stub ssh
# (lab-docker.d/bin/ssh) that echoes the remote command line.

(use judge)
(use sh)
(import hey)

(def- script (hey/path :home "bin/lab.d/docker.zsh"))
(def- stubs (hey/path :test "hey/lab-docker.d/bin"))

(defn- dk [& args]
  (hey/with-envvars ["PATH" (string stubs ":" (os/getenv "PATH"))]
    (string/split "\n" ($<_ ,script ,;args < :null))))

(deftest docker/passthrough
  (test (dk "ps" "-a") @["docker ps -a"]))

(deftest docker/ssh
  # No tty under the test, so no -t either.
  (test (dk "ssh" "foo") @["docker exec -i foo bash"])
  (test (dk "ssh" "foo" "sh" "-l") @["docker exec -i foo sh -l"]))

(deftest docker/ssh-completes-like-exec
  (test (dk "__complete" "ssh" "")
        @["docker __complete exec ''" "foo\tA container" ":4"]))

(deftest docker/ssh-in-the-menu
  (test (dk "__complete" "")
        @["docker __complete ''" "foo\tA container"
          "ssh\tOpen a shell in a running container" ":4"])
  (test (dk "__complete" "s")
        @["docker __complete s" "foo\tA container"
          "ssh\tOpen a shell in a running container" ":4"])
  (test (dk "__complete" "p")
        @["docker __complete p" "foo\tA container" ":4"]))
