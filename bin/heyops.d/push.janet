#!/usr/bin/env janet
# Build SYSTEM's configuration and hand it the result.
#
# SYNOPSIS:
#   heyops push SYSTEM [-b HOST|-l] [ARGS...]
#
# DESCRIPTION:
#   nixos-rebuild does all of it: --target-host activates over ssh, --build-host
#   decides who compiles. The default is to compile here, which is the whole
#   point -- this machine is faster than anything I would be pushing to.
#
#   ARGS go to nixos-rebuild as-is, so the action lives there too:
#   `heyops push soba boot`, `heyops push soba dry-activate`. With none, switch.
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
#   ** ARGS @default

(use hey)
(use hey/cmd)
(use sh)
(import hey/ops)

(defcmd push [_ system & args &opts
              builder [-b --builder host]
              local?  [-l --local]]
  (unless system (usage))
  (when (and builder local?)
    (abort "-b and -l are the same decision; pick one"))
  (ops/check system)

  # The flake reads this to know which host it is building. Without the swap it
  # would hand SYSTEM my hostname and cheerfully build the wrong machine.
  (os/setenv "HEYENV" (ops/heyenv system))
  (log "HEYENV=%s" (os/getenv "HEYENV"))

  (or (do? $? nixos-rebuild
           ,;(if (empty? args) ["switch"] args)
           --flake ,(string (path :home) "#" system)
           --target-host ,system
           ,;(opts "--build-host" (if local? system builder))
           --impure
           --show-trace)
      (exit 1)))
