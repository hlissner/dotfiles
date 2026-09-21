#!/usr/bin/env janet
# Rebuild this flake (using nixos-rebuild).
#
# SYNOPSIS:
#   sync [--fast] [--host HOST] [COMMAND] [ARGS...]
#   sync rollback [GENERATION]
#   sync build-image [VARIANT]
#
# DESCRIPTION:
#   Dynamically constructs --option {substituters,trusted-public-keys} from the
#   nix config, ensurign that there is no binary cache miss on the first
#   invocation of `hey sync` (use --fast to skip that).
#
# OPTIONS:
#   --fast
#     Skip nix's evaluation checks and building the substitutors options from
#     nix.settings.
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
(use hey/cmd)
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
  ``Point /etc/dotfiles at wherever I actually keep them. install.zsh clones
  over https and leaves the repo under /etc, but I move it afterwards, and
  shell/zsh.nix and agenix.nix pathExists their way into hey.dir while nix is
  evaluating -- they find nothing, quietly, if the two disagree.

  A real directory there gets asked about first. Whatever it is, it isn't mine
  to rm on a hunch.``
  [&opt link]
  (default link "/etc/dotfiles")
  (def home (path :home))
  (def real (ignore-errors (os/realpath link)))
  (unless (= real home)
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

# nix.settings reaches /etc/nix/nix.conf only when a generation activates, so
# without these the first sync after adding a cache builds everything, like
# Hyprland's or Noctalia's flakes.
(defn- cache-options-of
  ``The --option flags for the caches a host's nix.settings declares.``
  [flake-ref]
  (def text
    (ignore-errors
      ($<_ nix eval --impure --raw --no-warn-dirty
           ,(string flake-ref ".config.nix.settings")
           --apply `s: builtins.concatStringsSep "\n" (builtins.filter (l: l != "") (map (n: let v = s.${n} or []; in if v == [] then "" else "extra-${n} " + builtins.concatStringsSep " " v) [ "substituters" "trusted-public-keys" ]))`)))
  (unless text
    (echof :warn "Couldn't read nix.settings off the flake; rebuilding without its caches"))
  (def out @[])
  (each line (string/split "\n" (or text ""))
    (def at (string/find " " line))
    (when (and at (< (inc at) (length line)))
      (array/push out "--option" (string/slice line 0 at) (string/slice line (inc at)))))
  out)

(defcmd sync [_ cmd & args &opts fast? --fast host [--host name]]
  (when (= (flake :host) "nixos")
    (abort "HOST is 'nixos'. Did you forget to change it?"))

  (unless (empty? (hey swap --list))
    (abort "There are swapped files among your dotfiles!"))

  (os/setenv "HEYENV" (flake/json))
  (log "HEYENV=%s" (os/getenv "HEYENV"))

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
    (do? $? nix flake check --impure
         --no-warn-dirty
         --no-use-registries
         --no-write-lock-file
         --no-update-lock-file
         ,(path :home))
    (let [host (or host (flake :host))]
      (do? $? sudo --preserve-env=HEYENV nixos-rebuild
           --show-trace
           --impure
           --flake ,(string (path :home) "#" host)
           # An extra eval of the whole host config is the last thing --fast wants.
           ,;(if fast?
               []
               (cache-options-of (string (path :home) "#nixosConfigurations." host)))
           ,;(opts fast?)
           ,;(opts (or cmd "switch"))
           ,;args))))
