#!/usr/bin/env janet
# Garbage collect and optimize the nix store.
#
# SYNOPSIS:
#   gc [-a] [-s] [-d] [-D]
#
# OPTIONS:
#   -a
#     GC both the user and system profiles.
#   -s
#     Only GC the system profile.
#   -d
#     Delete profiles and profile data older than 14d.
#   -D
#     Delete *all* old profiles. Overrules -d.

(use hey)
(use hey/cmd)
(use sh)

(defcmd gc [_ &opts
            all? -a
            system? -s
            delete-old? -d
            delete-all-old? -D]
  (def ncg-args
    (cond delete-all-old? ["-d"]
          delete-old?     ["--delete-older-than" "14d"]
          []))

  (when (or all? system?)
    (echo :g "> Cleaning your system profile...")
    (do? $ sudo nix-collect-garbage ,;ncg-args)
    (unless (empty? ncg-args)
      # nix-collect-garbage is a Nix tool, not a NixOS tool. It won't delete old
      # boot entries until another nixos-rebuild (which means we'll always have
      # 2 boot entries at any time). We avoid the expensive rebuild and clear
      # those boot entries by calling switch-to-configuration directly.
      (echo :g "> Deleting left-over boot entries...")
      (unless (do? $? sudo ,(path :profile "bin/switch-to-configuration") boot)
        (echo :warn "Couldn't prune boot entries; your next `hey sync` will"))))

  (when (or all? (not system?))
    (echo :g "> Running GC on user profiles...")
    (do? $ nix-collect-garbage ,;ncg-args))

  (echo :g "> Optimizing the nix store...")
  (do? $ nix-store --optimise)

  (echo :check "Done!"))
