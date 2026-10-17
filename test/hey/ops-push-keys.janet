#!/usr/bin/env janet
# Regression tests for bin/hey.d/ops.d/push-keys.janet.
#
# The far end is a directory and ssh, scp and ssh-copy-id are shell scripts
# (ops-push-keys.d/bin/*), the way test/hey/ops-edit.janet does it. The stubbed
# ssh runs what it's handed against that directory rather than faking a reply,
# so the tidy script's chmods and symlinks -- which are most of what this
# command is for -- are really executed and really checked.
#
# The scp stub refuses a directory, and refuses a destination that isn't there
# yet, because real scp does both and push-keys has to not walk into either.

(use judge)
(use sh)
(import hey)
(import spork/json)

(def- bin (hey/path :home "bin/hey"))
(def- stubs (hey/path :test "hey/ops-push-keys.d/bin"))
(def- workstation (hey/path :test "hey/ops.d/workstation"))

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
  ``Run `hey ops push-keys SYSTEM` against that far end, and return its exit
  code. ROLE is what the far end claims to be, which is not this machine's --
  the local role gate wants a workstation either way. VARIANT is what its
  os-release says; "installer" with MOUNTED gives it a /mnt to install onto
  (a string: that path already exists under it),
  PROFILE is what `nix eval` answers about the host (a struct, raw JSON when a
  null matters, or nil for a host the flake doesn't have), and STDIN is my
  answer to the prompt.``
  [system &named role copyid-exit variant mounted profile stdin]
  ($? rm -rf ,remote)
  ($? mkdir -p ,remote)
  (when mounted ($? mkdir -p ,(hey/path/join remote "mnt" (if (string? mounted) mounted ""))))
  (spit log "")
  (hey/with-envvars ["XDG_DATA_HOME" workstation
                     # Ahead of $PATH in lib/hey/lib.janet's exec-path, which
                     # hey rebuilds $PATH from before running anything.
                     "XDG_BIN_HOME" stubs
                     "XDG_CONFIG_HOME" config
                     "HEY_OPS_TEST_REMOTE" remote
                     "HEY_OPS_TEST_LOG" log
                     "HEY_OPS_TEST_ROLE" (or role "workstation")
                     "HEY_OPS_TEST_VARIANT" variant
                     "HEY_OPS_TEST_PROFILE" (cond (string? profile) profile
                                                     profile (string (json/encode profile)))
                     "HEY_OPS_TEST_COPYID_EXIT" (if copyid-exit
                                                 (string copyid-exit))]
    (first (run ,bin ops push-keys ,system < ,(or stdin "") > ,(buffer) > [stderr :null]))))

(defn- landed [& parts] (hey/path/join remote ".config/secrets" ;parts))
(defn- sent [] (sorted (or (hey/ignore-errors (os/dir (landed))) [])))
(defn- mode [path] (os/stat path :permissions))
(defn- linked? [path] (= :link (os/lstat path :mode)))
(defn- asked [] (string/split "\n" (string/trim (string (slurp log)))))
(defn- asked? [prefix] (truthy? (find |(string/has-prefix? prefix $0) (asked))))

# A host the flake really has: the prompt's answer is checked against hosts/,
# and "box" (the ssh alias every test uses) is deliberately not one of them.
(def- a-host (first (sorted (os/dir (hey/path :hosts)))))
(def- profile {:user "someone" :role "server" :home "/home/someone" :uid 1234 :gid 100})
# A struct can't hold a nil, so a null goes in as a placeholder and comes out
# as JSON text.
(defn- profile-without [key]
  (string/replace `"null"` "null" (string (json/encode (merge profile {key "null"})))))
(defn- mnt [& parts] (hey/path/join remote "mnt" ;parts))


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


(deftest push-keys/installer
  # Booted into the installer the far end can't say what it is, so I'm asked,
  # and the flake fills in the rest. The keys land where they'll be after the
  # install, owned by who'll own them, and the host keys go where agenix looks
  # for them as root.
  (secrets {a-host    {"id_ed25519"       "private"
                       "host_ed25519"     "hostprivate"
                       "host_ed25519.pub" "hostpublic"}
            "@server" {"global_ed25519" "shared"}
            "box"     {"wrong_ed25519" "the alias is not the host"}})
  (test (push-keys "box" :variant "installer" :mounted true
                   :profile profile :stdin (string a-host "\n"))
        0)
  (def home (mnt "home/someone"))
  (test (sorted (os/dir (hey/path/join home ".config/secrets")))
        @["global_ed25519" "host_ed25519" "host_ed25519.pub" "id_ed25519"])
  (test (mode (hey/path/join home ".config/secrets/id_ed25519")) "rw-------")
  # A server's ssh dir, since that's what the flake said it was.
  (test (linked? (hey/path/join home ".ssh/host_ed25519")) true)
  (test (sorted (os/dir (mnt "etc/ssh"))) @["host_ed25519" "host_ed25519.pub"])
  (test (mode (mnt "etc/ssh/host_ed25519")) "rw-------")
  (test (mode (mnt "etc/ssh/host_ed25519.pub")) "rw-r--r--")
  # Nothing in the installer user's $HOME, staged or otherwise.
  (test (sent) @[])
  (test (hey/path/exists? (hey/path/join remote "host_ed25519")) false)
  (test (asked? (string "nix: eval nixosConfigurations." a-host ".config")) true)
  (test (asked? "sudo: mkdir") true)
  (test (asked? "chown: 1234:100 ") true))

(deftest push-keys/installer-default-host
  # SYSTEM naming a host is the usual case, and an empty answer takes it. A
  # home that's already there (a /home partition I kept) keeps its owner, too,
  # whatever the flake thinks.
  (secrets {a-host {"host_ed25519" "hostprivate"}})
  (test (push-keys a-host :variant "installer" :mounted "home/someone" :profile profile :stdin "\n") 0)
  (test (hey/path/exists? (mnt "home/someone/.config/secrets/host_ed25519")) true)
  # chown is a stub, so the owner is still whoever mkdir'd it: me.
  (def owner (let [st (os/stat (mnt "home/someone"))]
               (string (st :uid) ":" (st :gid))))
  (test (asked? (string "chown: " owner " ")) true)
  (test (asked? "chown: 1234:100 ") false))

(deftest push-keys/installer-unknown-host
  # No answer and nothing to default to, an answer that isn't in hosts/, and
  # one that is but the flake doesn't build: each stops before anything is sent.
  # The role directory is there so that a made-up host with a stubbed profile
  # would otherwise have something to send.
  (secrets {a-host {"host_ed25519" "hostprivate"}
            "@server" {"global_ed25519" "shared"}})
  (test (push-keys "box" :variant "installer" :mounted true :profile profile) 127)
  (test (push-keys "box" :variant "installer" :mounted true :profile profile :stdin "nope\n") 127)
  (test (push-keys "box" :variant "installer" :mounted true :stdin (string a-host "\n")) 127)
  (test (asked? "scp:") false))

(deftest push-keys/installer-no-user
  # A host config without a user or role is nothing to deduce from, and I'd
  # rather be told than have the keys land under /mnt/home/.
  (secrets {a-host {"host_ed25519" "hostprivate"}})
  (test (push-keys "box" :variant "installer" :mounted true :stdin (string a-host "\n")
                   :profile (profile-without :user))
        127)
  (test (push-keys "box" :variant "installer" :mounted true :stdin (string a-host "\n")
                   :profile (profile-without :role))
        127)
  (test (asked? "scp:") false))

(deftest push-keys/installer-nothing-mounted
  # /mnt with nothing on it is the ISO's tmpfs, and keys put there are gone at
  # reboot, with nothing to say so until agenix can't decrypt a thing.
  (secrets {a-host {"host_ed25519" "hostprivate"}})
  (test (push-keys "box" :variant "installer" :profile profile :stdin (string a-host "\n")) 127)
  (test (hey/path/exists? (mnt "home")) false))
