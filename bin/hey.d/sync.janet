#!/usr/bin/env janet
# Rebuild this flake (using nixos-rebuild).
#
# SYNOPSIS:
#   sync [--fast] [--host HOST] [COMMAND] [ARGS...]
#   sync rollback [GENERATION]
#
# OPTIONS:
#   --fast
#     Skip nix's evaluation checks.
#   --host HOST @hosts
#     Build the config of another host.
#
# ARGUMENTS:
#   1 COMMAND
#     switch                    -- Build, activate, and make the default boot entry.
#     boot                      -- Build and make the default boot entry.
#     test                      -- Build and activate, but do not add a boot entry.
#     build                     -- Build only.
#     dry-build                 -- Show what would be built.
#     dry-activate              -- Show what would be activated.
#     build-vm                  -- Build a VM of this flake.
#     build-vm-with-bootloader  -- Build a VM with a bootloader.
#     rollback                  -- Switch back to an older generation.
#     check                     -- Run nix flake check.
#   * ARGS @sync-arg

(use hey)
(use hey/cmd)
(use sh)

(defcmd sync [_ cmd & args &opts fast? --fast host [--host name]]
  (when (= (flake :host) "nixos")
    (abort "HOST is 'nixos'. Did you forget to change it?"))

  (unless (empty? (hey swap --list))
    (abort "There are swapped files among your dotfiles!"))

  (os/setenv "HEYENV" (flake/json))
  (log "HEYENV=%s" (os/getenv "HEYENV"))

  (case* cmd
    "rollback"
    (if (empty? args)
      # Neither form can go through the rebuild below: --rollback is mutually
      # exclusive with --flake, and nix-env isn't nixos-rebuild at all. Nothing
      # is evaluated either way, so neither wants the flake.
      (do? $? sudo nixos-rebuild switch --rollback)
      (do? $? sudo nix-env
           --switch-generation ,(in args 0)
           --profile ,(path :profile)))
    ["check" "ch"]
    (do? $? nix flake check --impure
         --no-warn-dirty
         --no-use-registries
         --no-write-lock-file
         --no-update-lock-file
         ,(path :home))
    (do? $? sudo --preserve-env=HEYENV nixos-rebuild
         --show-trace
         --impure
         --flake ,(string (path :home) "#" (or host (flake :host)))
         ,;(opts fast?)
         ,;(opts (or cmd "switch"))
         ,;args)))
