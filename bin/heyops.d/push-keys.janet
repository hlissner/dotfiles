#!/usr/bin/env janet
# Give SYSTEM the secrets it is supposed to have.
#
# SYNOPSIS:
#   heyops push-keys SYSTEM
#
# DESCRIPTION:
#   My public key goes over first, so nothing after it asks for a password.
#   Then ~/.config/secrets/SYSTEM and ~/.config/secrets/@ROLE follow it, where
#   ROLE is whatever SYSTEM says it is, and the host_* keys among them get
#   linked into wherever that role keeps its ssh config.
#
#   Idempotent, or as near as makes no difference: ssh-copy-id skips keys that
#   are already there and everything else is mkdir -p, chmod, and ln -sfn.
#
#   REQUIRES: ssh, ssh-copy-id, scp
#
# ARGUMENTS:
#   1 SYSTEM @hosts

(use hey)
(use hey/cmd)
(use sh)
(import hey/ops)

# Run on the far end, once, after the files land. Private keys are whatever
# isn't a .pub -- ssh refuses to read a private key anyone else can.
#
# find rather than a glob and a loop, because ssh runs this in the login shell
# and mine is zsh, which makes an unmatched glob a fatal error instead of
# leaving it alone. A machine with no host keys took the whole command down.
(defn- tidy [role]
  (string `
    set -eu
    secrets="$HOME/.config/secrets"
    mkdir -p "$secrets" "$HOME/.ssh" "$HOME/.config/ssh"
    chmod 700 "$HOME/.ssh" "$HOME/.config/ssh" "$secrets"
    find "$secrets" -maxdepth 1 -type f ! -name '*.pub' -exec chmod 600 {} +
    find "$secrets" -maxdepth 1 -type f -name '*.pub' -exec chmod 644 {} +
    find "$secrets" -maxdepth 1 -type f -name 'host_*' -exec ln -sf -t "` (ops/ssh-dir role) `" {} +
  `))

(defcmd push-keys [_ system]
  (unless system (usage))

  # First, so the checks below and every run after this one go through quietly.
  (unless (do? $? ssh-copy-id ,system)
    (abort "Couldn't put my key on %s" system))

  (def role (get (ops/check system) :role ""))
  (def dirs (filter path/directory?
                    [(path/xdg :config "secrets" system)
                     (path/xdg :config "secrets" (string "@" role))]))
  (when (empty? dirs)
    (abort "Nothing to send: no secrets/%s and no secrets/@%s" system role))

  (do? $? ssh ,system "mkdir -p ~/.config/secrets")
  (each dir dirs
    # Files only: scp without -r refuses a directory, and the far end's tidy
    # skips anything that isn't a regular file anyway.
    (def files (filter path/file? (path/files-in dir)))
    (if (empty? files)
      (log "%s is empty, skipping" (path/abbrev dir))
      (unless (do? $? scp -q ,;files ,(string system ":.config/secrets/"))
        (abort "Couldn't copy %s to %s" (path/abbrev dir) system))))

  (unless (do? $? ssh ,system ,(tidy role))
    (abort "Couldn't set up %s's key directories" system))
  (echo :check (fmt "%s has its keys (role: %s)" system role)))
