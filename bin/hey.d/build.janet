#!/usr/bin/env janet
# TODO
#
# SYNOPSIS:
#   build ...

(use hey)
(use hey/cmd)

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

(defn- build-hey [&opt all?]
  (os/cd (path :home))
  (when all?
    (echo :g "> Building bin/hey's dependencies...")
    (do? $ jpm deps ,;(opts (if (debug?) "--verbose"))))
  (echo :g "> Building & deploying bin/hey...")
  (do? $ jpm run deploy ,;(opts (if (debug?) "--verbose")))
  (echo :check "Done!"))

(defcmd build [_ cmd & args]
  (case* cmd
    "iso" ((cmdfn [all? -a] (build-iso all?)) ;args)
    ["vm" "vm-with-bootloader"] (build-vm cmd)
    (if (or (nil? cmd) (string/has-prefix? "-" cmd))
      (build-hey cmd ;args)
      (abort "Unknown build command: %s" cmd))))
