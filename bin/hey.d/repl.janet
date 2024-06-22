#!/usr/bin/env janet
# Open a nix or janet repl with this flake preloaded.
#
# SYNOPSIS:
#   repl [FLAKES...]
#
# OPTIONS:
#   -j
#     Start a Janet REPL instead.
#

(use hey)
(use hey/cmd)

(defcmd repl [_ & args &opts
              janet? -j
              nixdev? -d]
  (os/setenv "HEYENV" (flake/json))
  (cond janet?
        (do (echo :g "Starting Janet REPL (w/ HeyLib preloaded)...")
            (do? $ janet
                 -l hey
                 -l hey/cmd
                 -e "(import hey/vars)"
                 -e "(import hey/glob)"
                 -e "(import hey/sys)"
                 -p -r ,;args))

        nixdev?
        (do (echo :g "Starting nix-develop REPL (w/ flake preloaded)...")
            (do? $ nix develop ,(path :home) ,;args))

        (do (echo :g "Starting nix REPL (w/ flake preloaded)...")
            (do? $ nix repl
                 --extra-experimental-features "flakes repl-flake"
                 --impure
                 ,(path :home)
                 ,;args))))
