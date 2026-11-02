#!/usr/bin/env janet
# Sync this flake to SYSTEM, build it, and push the result there.
#
# SYNOPSIS:
#   hey ops push SYSTEM [HOST] [-b HOST|-l] [--dotfiles] [ARGS...]
#
# DESCRIPTION:
#   First syncs these dotfiles to /etc/dotfiles on the remote, then hands off to
#   nixos-rebuild: --target-host activates over ssh, --build-host decides who
#   builds it. The default is to build here and push the results to SYSTEM.
#
#   SYSTEM is the SSH address; HOST is the name of the hosts/HOST config to use
#   (in case SYSTEM doesn't match HOST). ARGS are forwarded to nixos-rebuild,
#   e.g. `hey ops push soba boot`, `hey ops push soba dry-activate`. Defaults to
#   `switch`.
#
# OPTIONS:
#   -b, --builder HOST @hosts
#     Compile on HOST instead of here.
#   -l, --local
#     Compile on SYSTEM itself. Same as -b SYSTEM, and worth it when the link
#     between us is slower than its CPU is bad.
#   --dotfiles
#     Only rsync the dotfiles; don't rebuild.
#
# ARGUMENTS:
#   1 SYSTEM @hosts
#   2 HOST @hosts
#   ** ARGS @default

(use hey)
(use sh)
(import hey/ops)

(defn- host? [name]
  (and name (path/directory? (path :hosts name))))

(defcmd push [_ system & args &opts
              builder   [-b --builder host]
              local?    [-l --local]
              dotfiles? [-d --dotfiles]]
  (unless system (usage))
  (when (and builder local?)
    (abort "-b and -l are the same decision; pick one"))
  (when (and dotfiles? (or builder local? (not (empty? args))))
    (abort "--dotfiles never builds, so -b, -l and ARGS have nothing to do"))
  (def named? (host? (first args)))
  (def host (if named? (first args) system))
  (def args (if named? (drop 1 args) args))
  (unless (or dotfiles? (host? host))
    (abort "No hosts/%s to build; name one: hey ops push %s HOST" host system))

  (def dest (get (ops/check system) :path ""))
  (when (empty? dest)
    (abort "%s wouldn't say where its dotfiles live" system))

  (unless (do? $? rsync -rltDzPJ
                "--include=.git/"
                "--filter=:- .gitignore"
                ,(string "--filter=:- " (path/xdg :config "git/ignore"))
                --delete --delete-after
                ,(string (path :home) "/")
                ,(string system ":" dest "/"))
    (exit 1))

  (unless dotfiles?
    (or (do? $? nixos-rebuild
             ,;(if (empty? args) ["switch"] args)
             --flake ,(string (path :home) "#" host)
             --target-host ,system
             ,;(opts "--build-host" (if local? system builder))
             --accept-flake-config
             --show-trace)
        (exit 1))))
