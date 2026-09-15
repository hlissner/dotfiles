#!/usr/bin/env janet
# Build nix images.
#
# SYNOPSIS:
#   build iso
#   build vm|vm-with-bootloader
#
# ARGUMENTS:
#   1 TARGET
#     iso                       -- Build an ISO for this host.
#     vm                        -- Build a VM of this flake.
#     vm-with-bootloader        -- Build a VM with a bootloader.
#   ** ARGS @default

(use hey)
(use hey/cmd)
(use sh)

(defn- build-vm [type & args]
  (echo :g "> Building an VM of this flake...")
  (hey sync -- ,;args ,(string "build-" type)))

(defn- build-iso [& args]
  (echo :g "> Building an ISO for this host...")
  (do? $ nix build
       ,(string/format "%s#nixosConfigurations.%s.config.system.build.isoImage"
                       (path :home) (flake :host))
       --profile ,(path :profile)
       --print-out-paths))

(defcmd build [_ cmd & args]
  (case* cmd
    "iso" (build-iso ;args)
    ["vm" "vm-with-bootloader"] (build-vm cmd)
    (if (nil? cmd)
      (abort "No build target specified")
      (abort "Unknown build command: %s" cmd))))
