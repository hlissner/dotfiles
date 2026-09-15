# lib/hey/ops.janet
#
# What every heyops subcommand needs before it touches another machine: a way
# in, and some idea of what it is on the other end.

(use ./.)
(use sh)

# One round trip for everything worth knowing. /etc/os-release is where the
# installer ISO admits to being one, and hey is how I tell a system of mine from
# any other nixos.
(def- *probe* `
  . /etc/os-release 2>/dev/null
  printf 'variant=%s\n' "${VARIANT_ID-}"
  if command -v hey >/dev/null 2>&1; then
    printf 'hey=1\nrole=%s\npath=%s\n' \
      "$(hey info profiles role -r 2>/dev/null)" \
      "$(hey path home 2>/dev/null)"
  else
    printf 'hey=0\n'
  fi
`)

(defn- keyvals [text]
  (def out @{})
  (each line (string/split "\n" text)
    (when-let [i (string/find "=" line)]
      (put out (keyword (slice line 0 i)) (string/trim (slice line (inc i))))))
  out)

(defn probe
  "What HOST says it is, or nil if ssh never got there."
  [host]
  (def out @"")
  (when ($? ssh ,host ,*probe* > ,out)
    (keyvals (string out))))

(defn check
  ``Reachable, installed, and mine -- in that order, so the complaint names the
  thing that's actually wrong rather than the first thing I noticed.``
  [host]
  (def facts (or (probe host) (abort "Can't reach %s over ssh" host)))
  (cond
    (= "installer" (facts :variant))
    (abort "%s is booted into the nixos installer; install.zsh is what you want" host)

    (not= "1" (facts :hey))
    (abort "No hey on %s -- is it one of mine?" host))
  facts)

(defn ssh-dir
  ``Where ROLE keeps its ssh keys. Workstations turn on modules.xdg.ssh, which
  moves them out of ~/.ssh; nothing else does. Left for the remote shell to
  expand, since it's the one that knows its own $HOME.``
  [role]
  (if (= "workstation" role) "$HOME/.config/ssh" "$HOME/.ssh"))

(defn heyenv
  "The HEYENV this flake wants, aimed at HOST instead of at me."
  [host]
  (string (json/encode (merge (flake) {:host host}))))
