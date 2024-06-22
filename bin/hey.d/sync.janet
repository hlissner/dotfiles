#!/usr/bin/env janet
# TODO
#
# SYNOPSIS:
#   sync [...]
#   sync --rollback [GENERATION]

(use hey)
(use hey/cmd)

(defcmd sync [_ cmd & args &opts fast? --fast]
  (when (= (flake :host) "nixos")
    (abort "HOST is 'nixos'. Did you forget to change it?"))

  (unless (empty? (hey swap --list))
    (abort "There are swapped files among your dotfiles!"))

  (os/setenv "HEYENV" (flake/json))
  (log "HEYENV=%s" (os/getenv "HEYENV"))

  (case* cmd
    "rollback"
    (if (empty? args)
      (array/push args "--rollback" "switch")
      (do (do? $? sudo nix-env
               --switch-generation ,(in args 0)
               --profile ,(path :profile))
          (break)))
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
         --flake ,(string (path :home) "#" (flake :host))
         ,;(opts fast?)
         ,;(opts (or cmd "switch"))
         ,;args)))
