#!/usr/bin/env janet
# Regression tests for bin/heyops.d/edit.janet.
#
# The far end is a directory and ssh is a shell script (edit.d/bin/ssh), because
# what's worth pinning here is which files heyops decides to send back, and that
# decision has no business needing another machine to check. This is the one
# command in here that writes to a machine I'm not looking at, so it gets the
# coverage the read-only ones don't. What it *says* while doing so isn't
# pinned; what lands on the far end and what exit code comes back are.

(use judge)
(use sh)
(import hey)

(def- bin (hey/path :home "bin/heyops"))
(def- stubs (hey/path :test "heyops/edit.d/bin"))
(def- workstation (hey/path :test "heyops/heyops.d/workstation"))

# The far end lives in hey's runtime dir: per-user tmpfs, gone at logout. The
# pid is in the name because judge runs the suites side by side.
(def- scratch
  (let [dir (hey/path :runtime "test.d")]
    (os/mkdir (hey/path :runtime))
    (os/mkdir dir)
    |(hey/path/join dir (string "edit-" (os/getpid) "." $0))))

(def- remote (scratch "remote"))
(def- log    (scratch "log"))

(defn- remote-files
  "Lay out the far end's $HOME, and hand back what's in it afterwards."
  [files]
  ($? rm -rf ,remote)
  (each [name text] (pairs files)
    (def dest (hey/path/join remote name))
    ($? mkdir -p ,(hey/path/dirname dest))
    (spit dest text))
  nil)

(defn- remote-file [name]
  (hey/ignore-errors (string (slurp (hey/path/join remote name)))))

(defn- edit
  ``Run `heyops edit ARGS` against that far end, and return its exit code.
  EDIT is the line the editor appends (nil to leave every file alone), CODE
  what the editor exits with. DRY? puts heyops in dry-run mode, which is a
  global flag and so goes first.``
  [args &named edit code editor dry?]
  ($? rm -rf ,(hey/path :runtime "edit.d"))
  (spit log "")
  (hey/with-envvars ["XDG_DATA_HOME" workstation
                     # Ahead of $PATH in lib/hey/lib.janet's exec-path, which
                     # hey rebuilds $PATH from before running anything. A stub
                     # merely on $PATH would lose to the real ssh.
                     "XDG_BIN_HOME" stubs
                     "EDITOR" (or editor "editor")
                     "HEYOPS_TEST_REMOTE" remote
                     "HEYOPS_TEST_LOG" log
                     "HEYOPS_TEST_EDIT" edit
                     "HEYOPS_TEST_EDITOR_EXIT" (if code (string code))]
    (first (run ,bin ,;(if dry? ["-!"] []) edit ,;args > ,(buffer) > [stderr :null]))))

(defn- sent? [name]
  "True if the far end was asked to write NAME, rather than merely read it."
  (not= nil (string/find (string "cat \"$tmp\" >'" name "'") (slurp log))))

(defn- staged? [] (not (empty? (os/dir (hey/path :runtime "edit.d")))))


(deftest edit/round-trip
  (remote-files {".zshrc" "one\n" ".config/foo/bar.toml" "two\n"})
  (test (edit ["box:.zshrc" "box:.config/foo/bar.toml"] :edit "three") 0)
  # Both files come back changed, nested path and all.
  (test (remote-file ".zshrc") "one\nthree\n")
  (test (remote-file ".config/foo/bar.toml") "two\nthree\n")
  # The scratch copies don't outlive the sitting.
  (test (staged?) false))

(deftest edit/only-what-changed
  # The whole point of keeping a copy of what I fetched. An editor that opens
  # three files and saves one shouldn't put three files back.
  (remote-files {"kept" "same\n" "touched" "same\n"})
  (test (edit ["box:kept" "box:touched"]
              # Only the second one; the stub appends to everything, so the
              # asymmetry has to come from somewhere else.
              :editor "sh -c 'echo edited >>$2' --")
        0)
  (test (remote-file "kept") "same\n")
  (test (remote-file "touched") "same\nedited\n")
  (test (sent? "kept") false)
  (test (sent? "touched") true))

(deftest edit/nothing-changed
  (remote-files {".zshrc" "one\n"})
  (test (edit ["box:.zshrc"]) 0)
  (test (sent? ".zshrc") false))

(deftest edit/editor-said-no
  # :cq, and the point of it: whatever I did in there, it stays here -- and it
  # keeps what I did, because nowhere else has it.
  (remote-files {".zshrc" "one\n"})
  (test (edit ["box:.zshrc"] :edit "junk" :code 1) 127)
  (test (remote-file ".zshrc") "one\n")
  (test (sent? ".zshrc") false)
  (test (staged?) true))

(deftest edit/a-typo-is-not-a-new-file
  (remote-files {".zshrc" "one\n"})
  (test (edit ["box:.zshrx"] :edit "junk") 127)
  (test (remote-file ".zshrx") nil))

(deftest edit/the-colon-is-the-syntax
  # Neither half may be empty.
  (test (map |(edit [$0]) ["zshrc" "box:" ":.zshrc"]) @[127 127 127]))

(deftest edit/dry-run
  # -! has to keep the staging directory: nothing was written anywhere, so it is
  # still the only copy of what I typed. Cleaning up regardless is how this
  # silently ate an editing session.
  (remote-files {".zshrc" "one\n"})
  (test (edit ["box:.zshrc"] :edit "three" :dry? true) 0)
  (test (remote-file ".zshrc") "one\n")
  (test (sent? ".zshrc") false)
  (test (staged?) true))

(deftest edit/one-buffer-per-file
  # box:/etc/foo and box:etc/foo mirror to the same staged path, which would
  # share a buffer between them and then write it back to both.
  (remote-files {".zshrc" "one\n"})
  (test (edit ["box:.zshrc" "box:/.zshrc"]) 127))

(deftest edit/editor-overrides
  (remote-files {".zshrc" "one\n"})
  # -e beats $EDITOR.
  (test (edit ["-e" "editor" "box:.zshrc"] :edit "via -e" :editor "false") 0)
  (test (remote-file ".zshrc") "one\nvia -e\n")
  # With neither, it says so rather than guessing.
  (test (edit ["box:.zshrc"] :editor "") 127))
