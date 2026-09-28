#!/usr/bin/env janet
# Rebuild this flake (using nixos-rebuild).
#
# SYNOPSIS:
#   sync [--fast] [--host HOST] [COMMAND] [ARGS...]
#   sync rollback [GENERATION]
#   sync build-image [VARIANT]
#
# DESCRIPTION:
#   Passes --accept-flake-config so flake.nix's nixConfig is respected.
#
# OPTIONS:
#   --fast
#     Skip nixos-rebuild's re-exec before the new build.
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
#     build-image               -- Build a deployable image of the given VARIANT.
#     build-vm                  -- Build a VM of this flake.
#     build-vm-with-bootloader  -- Build a VM with a bootloader.
#     rollback                  -- Switch back to an older generation.
#     check                     -- Run nix flake check.
#   * ARGS @sync-arg

(use hey)
(use sh)

(defn- yes?
  ``Ask. Anything that isn't an explicit yes is a no -- including a closed
  stdin, because the only caller follows this with rm -rf.``
  [message & args]
  (prin (fmt "%s [y/N] " (fmt message ;args)))
  (flush)
  (def answer (string/ascii-lower (string/trim (or (file/read stdin :line) ""))))
  (string/has-prefix? "y" answer))

(defn- link-dotfiles
  ``Point /etc/dotfiles at the checkout I'm syncing from, when that isn't
  /etc/dotfiles itself (DOTFILES_HOME, i.e. the dev shell). The flake bakes
  /etc/dotfiles into everything it builds, so a link aimed elsewhere means the
  system I just switched to runs someone else's config/.

  A real directory there gets asked about first. Whatever it is, it isn't mine
  to rm on a hunch.``
  [&opt link]
  (default link "/etc/dotfiles")
  (def home (path :home))
  (def real (ignore-errors (os/realpath link)))
  (unless (or (= home link) (= real home))
    (when (= real link)
      (unless (or (dryrun?) (yes? "%s is a directory, not a link. Delete it?" link))
        (echof :warn "Left %s alone; it and hey.dir will keep disagreeing" link)
        (break))
      (do? $? sudo rm -rf ,link))
    (unless (do? $? sudo ln -sfn ,home ,link)
      (echof :warn "Couldn't point %s at %s" link (path/abbrev home)))))

(defn- image-args
  ``nixos-rebuild spells the image variant as a flag; I'd rather type it as the
  argument it reads like. A leading flag is left alone, so --image-variant still
  works if I reach for it, and no argument at all leaves nixos-rebuild to list
  what this host can actually build.``
  [args]
  (def variant (first args))
  (if (or (nil? variant) (string/has-prefix? "-" variant))
    args
    ["--image-variant" variant ;(drop 1 args)]))

(defcmd sync [_ cmd & args &opts fast? --fast host [--host name]]
  (when (= (flake :host) "nixos")
    (abort "HOST is 'nixos'. Did you forget to change it?"))

  (unless (empty? (hey swap --list))
    (abort "There are swapped files among your dotfiles!"))

  (def args (if (= cmd "build-image") (image-args args) args))

  (link-dotfiles)
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
    (do? $? nix flake check
         --accept-flake-config
         --no-warn-dirty
         --no-use-registries
         --no-write-lock-file
         --no-update-lock-file
         ,(path :home))
    (let [host (or host (flake :host))]
      (unless (do? $? sudo --validate)
        # Prompt for sudo password sooner than later
        (abort "Never got root; stopping before the long part"))
      (do? $? sudo nixos-rebuild
           --show-trace
           --flake ,(string (path :home) "#" host)
           --accept-flake-config
           ,;(opts (if fast? "--no-reexec"))
           ,;(opts (or cmd "switch"))
           ,;args))))
