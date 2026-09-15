#!/usr/bin/env janet
# Ask SYSTEM about itself.
#
# SYNOPSIS:
#   heyops info SYSTEM [ARGS...]
#
# DESCRIPTION:
#   `hey info`, run over there. ARGS go to it verbatim, so every flag and key
#   hey info takes works here: `heyops info soba profiles role -r`.
#
# ARGUMENTS:
#   1 SYSTEM @hosts
#   ** ARGS

(use hey)
(use hey/cmd)
(import hey/ops)

# Raw arguments, so hey info's own -r and -w survive the trip.
(defcmd info [_ & _ argv]
  (def [system & args] (slice argv 1))
  (unless system (usage))
  (ops/check system)
  (exit (os/execute
         ["ssh" system
          (string/join ["hey" "info" ;(map shell-quote args)] " ")]
         :p)))
