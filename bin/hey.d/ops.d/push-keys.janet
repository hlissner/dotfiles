#!/usr/bin/env janet
# Give SYSTEM the secrets it is supposed to have.
#
# SYNOPSIS:
#   hey ops push-keys SYSTEM
#
# DESCRIPTION:
#   ssh-copy-id my key to SYSTEM, then syncs
#   ~/.config/secrets/{$HOST,$USER,@$ROLE}/ to it (HOST, USER, and ROLE are
#   deduced from the remote system's profiles in `hey info`). If SYSTEM is
#   booted into the nixos installer, you'll be prompted to enter the hostname of
#   SYSTEM and the other values will be deduced from this flake's nix config.
#
#   REQUIRES: ssh, ssh-copy-id, scp
#
# ARGUMENTS:
#   1 SYSTEM @hosts

(use hey)
(use sh)
(import hey/ops)

(defn- tidy [role]
  # $sudo is empty everywhere but the installer.
  (string `
    secrets="$HOME/.config/secrets"
    $sudo mkdir -p "$secrets" "$HOME/.ssh" "$HOME/.config/ssh"
    $sudo chmod 700 "$HOME/.ssh" "$HOME/.config/ssh" "$secrets"
    $sudo find "$secrets" -maxdepth 1 -type f ! -name '*.pub' -exec chmod 600 {} +
    $sudo find "$secrets" -maxdepth 1 -type f -name '*.pub' -exec chmod 644 {} +
    $sudo find "$secrets" -maxdepth 1 -type f -name 'host_*' -exec ln -sf -t "` (ops/ssh-dir role) `" {} +
  `))

(defn- settle [role]
  (string "set -eu\nsudo=\n" (tidy role)))

# When in the nixos installer
(defn- settle-installer [role home owner names]
  (string `
    set -eu
    sudo=; [ "$(id -u)" = 0 ] || sudo=sudo
    mountpoint -q /mnt || { echo "nothing is mounted at /mnt" >&2; exit 1; }
    staging="$HOME"
    HOME="/mnt` home `"
    owner="$(stat -c %u:%g "$HOME" 2>/dev/null || echo "` owner `")"
    $sudo mkdir -p "$HOME/.config/secrets"
    for f in ` (string/join names " ") `; do $sudo mv -f "$staging/$f" "$HOME/.config/secrets/"; done
  ` "\n" (tidy role) "\n" `
    $sudo chown "$owner" "$HOME" "$HOME/.ssh" "$HOME/.config" "$HOME/.config/ssh"
    $sudo find "$secrets" -maxdepth 1 -exec chown -h "$owner" {} +
    $sudo find "` (ops/ssh-dir role) `" -maxdepth 1 -name 'host_*' -exec chown -h "$owner" {} +
    $sudo mkdir -p -m 755 /mnt/etc/ssh
    $sudo find "$secrets" -maxdepth 1 -type f -name 'host_*' ! -name '*.pub' -exec install -m 600 -t /mnt/etc/ssh {} +
    $sudo find "$secrets" -maxdepth 1 -type f -name 'host_*' -name '*.pub' -exec install -m 644 -t /mnt/etc/ssh {} +
  `))

(def- *extract* `
  c: let
    p = c.modules.profiles;
    u = if p.user == null then {} else c.users.users.${p.user} or {};
  in {
    inherit (p) user role;
    home = u.home or null;
    uid = u.uid or null;
    gid = c.users.groups.${u.group or ""}.gid or null;
  }
`)

(defn- deduce
  ``What the flake says HOST's user and role are, plus what it knows about that
  user's account. nil if HOST isn't a nixosConfiguration at all.``
  [host]
  (def out @"")
  (when ($? nix eval --json --no-warn-dirty
            --no-write-lock-file  # no side effects pls
            ,(string (path :home) "#nixosConfigurations." host ".config")
            --apply ,*extract* > ,out > [stderr :null])
    (json/decode (string out) :keywords true)))

(defn- ask-host
  ``Which host SYSTEM is becoming. SYSTEM itself when that names one of mine,
  unless I say otherwise; a closed stdin takes the default or nothing.``
  [system]
  (def default (when (path/directory? (path :hosts system)) system))
  (prin (fmt "Which host is being installed on %s?%s " system
             (if default (fmt " [%s]" default) "")))
  (flush)
  (def answer (string/trim (or (file/read stdin :line) "")))
  (def host (if (empty? answer) default answer))
  (cond
    (nil? host) (abort "No host given, and %s isn't one in hosts/" system)
    (not (path/directory? (path :hosts host))) (abort "No such host: hosts/%s" host))
  host)

(defn- secret-dirs [host role]
  (def dirs (filter path/directory?
                    [(path/xdg :config "secrets" host)
                     (path/xdg :config "secrets" (string "@" role))]))
  (when (empty? dirs)
    (abort "Nothing to send: no secrets/%s and no secrets/@%s" host role))
  dirs)

(defn- send
  ``scp each DIRS' files to DEST on SYSTEM. Files only: scp without -r refuses a
  directory, and the far end's tidy skips anything that isn't a regular file
  anyway. Returns what went over, by basename.``
  [system dirs dest]
  (seq [dir :in dirs
        :let [files (filter path/file? (path/files-in dir))]
        :when (if (empty? files)
                (do (log "%s is empty, skipping" (path/abbrev dir)) false)
                true)]
    (unless (do? $? scp -q ,;files ,(string system ":" dest))
      (abort "Couldn't copy %s to %s" (path/abbrev dir) system))
    (map path/basename files)))

(defn- push-to-system [system role]
  (def dirs (secret-dirs system role))
  (do? $? ssh ,system "mkdir -p ~/.config/secrets")
  (send system dirs ".config/secrets/")
  (unless (do? $? ssh ,system ,(settle role))
    (abort "Couldn't set up %s's key directories" system))
  (echo :check (fmt "%s has its keys (role: %s)" system role)))

(defn- push-to-installer [system]
  (echof :warn "%s is booted into the nixos installer" system)
  (def host (ask-host system))
  (def {:user user :role role :home home :uid uid :gid gid}
    (or (deduce host) (abort "%s isn't a nixosConfiguration in this flake" host)))
  (unless (and user role)
    (abort "Can't tell who %s is for: hosts/%s sets modules.profiles.user = %q and .role = %q"
           host host user role))
  (def dirs (secret-dirs host role))
  # users.users.USER.home is /home/USER unless told otherwise, and it never is.
  (def home (or home (string "/home/" user)))
  (echof :warn "Deploying %s's keys as %s (role: %s) under /mnt%s" host user role home)
  (def names (flatten (send system dirs "")))
  (unless (do? $? ssh ,system ,(settle-installer role home (fmt "%d:%d" (or uid 1000) (or gid 100)) names))
    (abort "Couldn't set up %s's key directories under /mnt%s" host home))
  (echo :check (fmt "%s has %s's keys (role: %s, user: %s, installer)" system host role user)))

(defcmd push-keys [_ system]
  (unless system (usage))

  # First, so the checks below and every run after this one go through quietly.
  (unless (do? $? ssh-copy-id ,system)
    (abort "Couldn't put my key on %s" system))

  (def facts (ops/check system :installer true))
  (if (ops/installer? facts)
    (push-to-installer system)
    (push-to-system system (get facts :role ""))))
