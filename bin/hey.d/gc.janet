#!/usr/bin/env janet
# Garbage collect and optimize the nix store.
#
# SYNOPSIS:
#   gc [-a|--all] [--system] [-d]
#
# OPTIONS:
#   -a
#     GC both the user and system profiles.
#   -s
#     Only GC the system profile.
#   -d
#     Delete old profiles as well.

(use hey)
(use hey/cmd)
(use sh)

(defcmd gc [_ &opts
            all? -a
            system? -s
            delete-old? -d]
  (when (or all? system?)
    (echo :g "> Cleaning your system profile...")
    (do? $ sudo nix-collect-garbage ,;(opts delete-old?))
    (try
      (when delete-old?
        # nix-collect-garbage is a Nix tool, not a NixOS tool. It won't delete
        # old boot entries until you do a nixos-rebuild (which means we'll
        # always have 2 boot entries at any time); reloading the current
        # environment deletes them immediately.
        (echo :g "> Deleting left-over boot entries...")
        (let [profile (path :profile)]
          (do? $ sudo nix-env --delete-generations old --profile ,profile)
          (do? $ sudo ,(string profile "/bin/switch-to-configuration") switch)))
      ([err fib]
       (propagate err fib)))

    (echo :g "> Optimizing the nix store...")
    (do? $ nix-store --optimise))

  (when (or all? (not system?))
    (echo :g "> Running GC on user profiles...")
    (do? $ nix-collect-garbage ,;(opts delete-old?)))

  (echo :check "Done!"))
