#!/usr/bin/env janet
# Open a shell on SYSTEM, or run one thing there.
#
# SYNOPSIS:
#   heyops ssh SYSTEM [ARGS...]
#
# DESCRIPTION:
#   Plain ssh with the sanity checks in front of it, so a typo'd hostname says
#   so instead of hanging. Everything after SYSTEM goes to ssh untouched --
#   flags of its own included.
#
# ARGUMENTS:
#   1 SYSTEM @hosts
#   ** ARGS @default

(use hey)
(use hey/cmd)
(import hey/ops)

# The raw arguments, not the parsed ones: cmdfn splits -tt into -t -t, and
# these are ssh's flags, not mine.
(defcmd ssh [_ & _ argv]
  (def [system & args] (slice argv 1))
  (unless system (usage))
  (ops/check system)
  (exit (os/execute ["ssh" system ;args] :p)))
