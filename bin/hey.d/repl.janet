#!/usr/bin/env janet
# Open a Janet REPL with hey's library loaded, or inside a script.
#
# SYNOPSIS:
#   repl [FILE]
#
# DESCRIPTION:
#   Without FILE, the REPL starts with hey, hey/vars, hey/glob and hey/sys
#   loaded. With it, FILE is evaluated and the REPL starts inside its
#   environment, private bindings and all. Its main isn't called, but the rest
#   of its top level runs, so a script that does its work there does it now.
#
#   For a Nix repl in this flake, use `nix develop`.
#
# ARGUMENTS:
#   1 FILE @files

(use hey)
(use sh)

(defcmd repl [_ file]
  # Whatever I poke at in there may shell out to nix against this flake.
  (os/setenv "HEYENV" (flake/json))
  (if file
    (do (unless (path/file? file)
          (abort "No such file: %s" file))
        (echof :g "Starting Janet REPL (inside %s)..." (path/abbrev file))
        # Avoiding -l b/c import only hands over public bindings
        (do? $ janet -e ,(string/format "(repl nil nil (dofile %j))" file)))
    (do (echo :g "Starting Janet REPL (w/ HeyLib preloaded)...")
        (do? $ janet
             -l hey
             -e "(import hey/vars)"
             -e "(import hey/glob)"
             -e "(import hey/sys)"
             -p -r))))
