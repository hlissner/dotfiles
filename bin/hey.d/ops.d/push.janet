#!/usr/bin/env janet
# Build SYSTEM's configuration and hand it the result.
#
# SYNOPSIS:
#   hey ops push SYSTEM [HOST] [-b HOST|-l] [ARGS...]
#
# DESCRIPTION:
#   nixos-rebuild does all of it: --target-host activates over ssh, --build-host
#   decides who compiles. The default is to compile here, which is the whole
#   point -- this machine is faster than anything I would be pushing to.
#
#   SYSTEM is only where ssh goes; HOST is which config it gets, and defaults to
#   SYSTEM. So `hey ops push ramen.lan ramen`, because there's no ramen.lan in
#   hosts/ and there never will be.
#
#   ARGS go to nixos-rebuild as-is, so the action lives there too: `hey ops
#   push soba boot`, `hey ops push soba dry-activate`. With none, switch. HOST
#   is only HOST if hosts/HOST exists, which is how boot stays an ARG.
#
# OPTIONS:
#   -b, --builder HOST @hosts
#     Compile on HOST instead of here.
#   -l, --local
#     Compile on SYSTEM itself. Same as -b SYSTEM, and worth it when the link
#     between us is slower than its CPU is bad.
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
              builder [-b --builder host]
              local?  [-l --local]]
  (unless system (usage))
  (when (and builder local?)
    (abort "-b and -l are the same decision; pick one"))
  (def named? (host? (first args)))
  (def host (if named? (first args) system))
  (def args (if named? (drop 1 args) args))
  (unless (host? host)
    (abort "No hosts/%s to build; name one: hey ops push %s HOST" host system))
  (ops/check system)

  (os/setenv "HEYENV" (ops/heyenv host))
  (log "HEYENV=%s" (os/getenv "HEYENV"))

  (or (do? $? nixos-rebuild
           ,;(if (empty? args) ["switch"] args)
           --flake ,(string (path :home) "#" host)
           --target-host ,system
           ,;(opts "--build-host" (if local? system builder))
           --accept-flake-config
           --impure
           --show-trace)
      (exit 1)))
