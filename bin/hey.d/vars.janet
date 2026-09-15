#!/usr/bin/env janet
# Get or set session or persistent state in userspace.
#
# SYNOPSIS:
#   vars [-g]
#   vars [-g] get VAR
#   vars [-g] set VAR VALUE
#
# OPTIONS:
#   -g
#     Operate on persistent (global) vars.
#
# ARGUMENTS:
#   1 COMMAND
#     get     -- Print a var.
#     set     -- Assign a var.
#   2 VAR @vars
#   3 VALUE

(use hey)
(use hey/cmd)
(import hey/vars)

(defcmd vars [_ cmd & args &opts global? -g]
  (echo ;(case cmd
          "get" [(vars/get (or (first args) (abort "No variable specified"))
                           global?)]
          "set" [(vars/set (or (first args) (abort "No variable specified"))
                           (get args 1) global?)]
          # As strings, or echo eats them: it reads leading keywords as its own
          # style flags, and every var name arrives as one.
          nil   (map string (vars/list global?))
          (abort "No such vars command: %s" cmd))))
