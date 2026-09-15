#!/usr/bin/env janet
# Regression tests for bin/heyops.d/push-keys.janet.
#
# The far end is a directory and ssh, scp and ssh-copy-id are shell scripts
# (push-keys.d/bin/*), the way test/heyops/edit.janet does it. The stubbed ssh
# runs what it's handed against that directory rather than faking a reply, so
# the tidy script's chmods and symlinks -- which are most of what this command
# is for -- are really executed and really checked.
#
# The scp stub refuses a directory, and refuses a destination that isn't there
# yet, because real scp does both and push-keys has to not walk into either.

(use judge)
(use sh)
(import hey)

(def- bin (hey/path :home "bin/heyops"))
(def- stubs (hey/path :test "heyops/push-keys.d/bin"))
(def- workstation (hey/path :test "heyops/heyops.d/workstation"))

# The far end lives in hey's runtime dir: per-user tmpfs, gone at logout. The
# pid is in the name because judge runs the suites side by side.
(def- scratch
  (let [dir (hey/path :runtime "test.d")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    |(hey/path/join dir (string "push-keys-" (os/getpid) "." $0))))

(def- remote (scratch "remote"))
(def- config (scratch "config"))
(def- log    (scratch "log"))

(defn- secrets
  ``Lay out $XDG_CONFIG_HOME/secrets from SPEC, as {DIR {FILE CONTENTS}}. A file
  whose contents are :dir becomes a directory instead, which is how something
  that isn't a key gets in among the keys.``
  [spec]
  ($? rm -rf ,config)
  (each [name files] (pairs spec)
    (def dir (hey/path/join config "secrets" name))
    ($? mkdir -p ,dir)
    (each [file contents] (pairs files)
      (def dest (hey/path/join dir file))
      (if (= contents :dir)
        ($? mkdir -p ,dest)
        (spit dest contents)))))

(defn- push-keys
  ``Run `heyops push-keys SYSTEM` against that far end, and return its exit
  code. ROLE is what the far end claims to be, which is not this machine's --
  the local role gate wants a workstation either way.``
  [system &named role copyid-exit]
  ($? rm -rf ,remote)
  ($? mkdir -p ,remote)
  (spit log "")
  (hey/with-envvars ["XDG_DATA_HOME" workstation
                     # Ahead of $PATH in lib/hey/lib.janet's exec-path, which
                     # hey rebuilds $PATH from before running anything.
                     "XDG_BIN_HOME" stubs
                     "XDG_CONFIG_HOME" config
                     "HEYOPS_TEST_REMOTE" remote
                     "HEYOPS_TEST_LOG" log
                     "HEYOPS_TEST_ROLE" (or role "workstation")
                     "HEYOPS_TEST_COPYID_EXIT" (if copyid-exit
                                                 (string copyid-exit))]
    (first (run ,bin push-keys ,system > ,(buffer) > [stderr :null]))))

(defn- landed [& parts] (hey/path/join remote ".config/secrets" ;parts))
(defn- sent [] (sorted (or (hey/ignore-errors (os/dir (landed))) [])))
(defn- mode [path] (os/stat path :permissions))
(defn- linked? [path] (= :link (os/lstat path :mode)))
(defn- asked [] (string/split "\n" (string/trim (string (slurp log)))))


(deftest push-keys/round-trip
  (secrets {"box" {"id_ed25519"       "private"
                   "id_ed25519.pub"   "public"
                   "host_ed25519"     "hostprivate"
                   "host_ed25519.pub" "hostpublic"}})
  (test (push-keys "box") 0)
  # Everything in the directory goes over.
  (test (sent) @["host_ed25519" "host_ed25519.pub" "id_ed25519" "id_ed25519.pub"])
  # A private key nobody else may read; a public one anyone may. ssh refuses
  # to use a private key with a mode looser than this, which is the whole
  # reason tidy exists.
  (test (mode (landed "id_ed25519")) "rw-------")
  (test (mode (landed "id_ed25519.pub")) "rw-r--r--")
  # Only the host keys get linked, and into the workstation's ssh dir:
  # modules.xdg.ssh moves ~/.ssh out from under itself on a workstation.
  (test (linked? (hey/path/join remote ".config/ssh/host_ed25519")) true)
  (test (hey/path/exists? (hey/path/join remote ".config/ssh/id_ed25519")) false)
  # My key goes first, before anything asks for a password.
  (test (first (asked)) "ssh-copy-id: box"))

(deftest push-keys/role-directory
  # No secrets/box at all: what the far end says it is picks the directory,
  # and a server keeps its ssh config where ssh looks by default.
  (secrets {"@server" {"host_ed25519" "hostprivate"}})
  (test (push-keys "box" :role "server") 0)
  (test (sent) @["host_ed25519"])
  (test (linked? (hey/path/join remote ".ssh/host_ed25519")) true))

(deftest push-keys/a-directory-among-the-keys
  # path/files-in is os/dir joined, directories included, and scp without -r
  # refuses one -- which used to take the whole command down with it.
  (secrets {"box" {"id_ed25519" "private"
                   "old" :dir}})
  (test (push-keys "box") 0)
  (test (sent) @["id_ed25519"]))

(deftest push-keys/nothing-to-glob
  # ssh runs tidy in the far end's login shell, and mine is zsh, where an
  # unmatched glob is fatal rather than left alone. Both of tidy's loops had
  # one: a machine with no host keys still gets its user keys, and an empty
  # directory is nothing to send, not an error.
  (secrets {"box" {"id_ed25519" "private" "id_ed25519.pub" "public"}})
  (test (push-keys "box") 0)
  (test (sent) @["id_ed25519" "id_ed25519.pub"])

  (secrets {"box" {}})
  (test (push-keys "box") 0)
  (test (sent) @[]))

(deftest push-keys/nothing-to-send
  (secrets {"someone-else" {"id_ed25519" "private"}})
  (test (push-keys "box") 127)
  (test (sent) @[]))

(deftest push-keys/no-key-no-keys
  # If my key won't go over, everything after it would sit there asking for a
  # password, so it stops here -- without even asking what the far end was.
  (secrets {"box" {"id_ed25519" "private"}})
  (test (push-keys "box" :copyid-exit 1) 127)
  (test (sent) @[])
  (test (asked) @["ssh-copy-id: box"]))
