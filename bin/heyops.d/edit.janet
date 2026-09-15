#!/usr/bin/env janet
# Edit files on other machines with the editor on this one.
#
# SYNOPSIS:
#   heyops edit [-e EDITOR] SYSTEM:FILE...
#
# DESCRIPTION:
#   Fetches every FILE, opens the lot in one editor, and sends back the ones
#   that came out different. Several files on several machines in one sitting:
#
#     heyops edit ramen:.zshrc soba:.config/foo.toml
#
#   FILE is whatever SYSTEM's login shell makes of it, which means relative to
#   $HOME unless it starts with a /.
#
#   Nothing goes back if the editor exits non-zero -- :cq is how I change my
#   mind -- or if a file came back byte-for-byte identical. A file that isn't
#   there is an error rather than an invitation: a fat-fingered path should not
#   quietly become a new file on a machine I'm not sitting at.
#
#   Nobody checks whether the far end changed while I had the file open. Don't
#   edit the same file from two directions at once.
#
#   REQUIRES: ssh
#
# OPTIONS:
#   -e, --editor EDITOR
#     Use EDITOR instead of $EDITOR.
#
# ARGUMENTS:
#   * TARGET @edit-target

(use hey)
(use hey/cmd)
(use sh)
# Aliased because `sh` is already janet-sh here, and spork's is the one with
# mkdir -p in it.
(import spork/sh :as fs)
(import hey/ops)

# Private, and on tmpfs: these are other machines' config files, and some of
# them have secrets in. The pid keeps two sittings out of each other's way.
(defn- stage [& args] (path :runtime "edit.d" (string (os/getpid)) ;args))

(defn- target
  ``Split SYSTEM:FILE. The colon is the entire syntax, so say so, rather than
  going off to look for a machine named "zshrc".``
  [text]
  (def i (string/find ":" text))
  (unless (and i (pos? i) (< (inc i) (length text)))
    (abort "%s: not a SYSTEM:FILE" text))
  (let [system (slice text 0 i)
        file   (slice text (inc i))]
    @{:system system
      :file   file
      # Mirrored under the system's name, so two machines' .zshrc are two
      # buffers and the editor's tab line says which is which.
      :local  (stage system (string/trim file "/"))}))

(defn- fetch [job]
  (fs/create-dirs (path/dirname (job :local)))
  # ssh lands me in $HOME, so a relative FILE resolves there without my help.
  (unless (with [f (file/open (job :local) :w)]
            ($? ssh ,(job :system) ,(string "cat -- " (shell-quote (job :file))) > ,f))
    (abort "%s:%s: couldn't read that" (job :system) (job :file)))
  # A string, not slurp's buffer: janet compares buffers by identity, so every
  # file would come out "changed" and the whole point of this would be lost.
  (put job :before (string (slurp (job :local)))))

(defn- changed? [job]
  (def after (ignore-errors (string (slurp (job :local)))))
  (cond
    (nil? after)
    (do (echof :warn "%s:%s: gone from under me; leaving the remote alone"
               (job :system) (job :file))
      false)

    (not= after (job :before))))

(defn- send [job]
  # Fill a temp file from the network first and only truncate the real one once
  # that worked, so a connection dying halfway doesn't leave an empty config on
  # a machine I'm not sitting at. Redirecting into the file rather than moving
  # over it keeps its inode, mode and owner.
  (def script
    (fmt `tmp=$(mktemp) && cat >"$tmp" && cat "$tmp" >%s && rm -f "$tmp"`
         (shell-quote (job :file))))
  # Not do?: it stringifies the < and hands posix-spawn a file object.
  (if (dryrun?)
    (do (echof :y "DRYRUN: would write %s:%s" (job :system) (job :file)) true)
    (let [sent? (with [f (file/open (job :local))]
                  ($? ssh ,(job :system) ,script < ,f))]
      (if sent?
        (echof :check "%s:%s" (job :system) (job :file))
        (echof :error "%s:%s: couldn't write that back" (job :system) (job :file)))
      sent?)))

(defn- discard
  ``Throw the sitting away. Not in a dry run: nothing went anywhere, so the
  staged copies are still the only place my edits exist.``
  []
  (if (dryrun?)
    (echof :y "DRYRUN: left your edits in %s" (stage))
    ($? rm -rf ,(stage))))

(defcmd edit [_ & targets &opts editor [-e --editor name]]
  (when (empty? targets) (usage))
  # What I typed, before what my environment forgot to set: a mistyped target is
  # my fault and a missing $EDITOR isn't, and the first is the one I can fix.
  (def jobs (map target targets))
  # Two targets that mirror to one staged path would share a buffer and then be
  # written back to both ends of it. box:/etc/foo and box:etc/foo is the way in,
  # since the mirror drops the leading slash.
  (unless (= (length jobs) (length (distinct (map |($0 :local) jobs))))
    (abort "Two of those stage to the same file; one sitting each"))
  # An empty $EDITOR is an unset one. Left alone it becomes `sh -c ' "$@"'`,
  # which succeeds at running nothing, and I'd be told I changed my mind.
  (def named? |(unless (or (nil? $0) (empty? $0)) $0))
  (def editor (or (named? editor)
                  (named? (os/getenv "EDITOR"))
                  (abort "No $EDITOR set, and no -e to stand in for it")))

  # One probe per machine, however many of its files I asked for.
  (each system (distinct (map |($0 :system) jobs))
    (ops/check system))
  (each job jobs (fetch job))

  # Through a shell, so an $EDITOR with arguments in it ("emacsclient -nw")
  # works here the way it does everywhere else. $0 is named rather than blank so
  # that a complaint from the shell says who asked.
  (def code (first (run sh -c ,(string editor ` "$@"`) heyops-edit
                        ,;(map |($0 :local) jobs))))
  (unless (zero? code)
    (echof :warn "Your edits are in %s" (stage))
    (abort "Editor exited %d; nothing written back" code))

  (def dirty (filter changed? jobs))
  (when (empty? dirty)
    (echo :y "Nothing changed; nothing sent")
    (discard)
    (break))

  # Whatever wouldn't go back stays here, because the edits only exist here.
  (if (every? (map send dirty))
    (discard)
    (do (echof :warn "Left the edits I couldn't send in %s" (stage))
      (exit 1))))
