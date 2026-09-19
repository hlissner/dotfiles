#!/usr/bin/env janet
# Get or set session or persistent state in userspace.
#
# SYNOPSIS:
#   vars [-g]
#   vars [-g] get VAR
#   vars [-g] [-v] set VAR VALUE
#
# DESCRIPTION:
#   A rudimentary state manager. `get` exits 1 when VAR isn't set, so a missing
#   var can be distinguished from an empty string.
#
#     hey get hypr.slurp.last || echo "nada"
#
#   `set` echoes the var's key. Pass -v when you'd rather have the value back,
#   to store and print in one go:
#
#     region="$(hey set -v hypr.slurp.last "$(slurp)")"
#
# OPTIONS:
#   -g
#     Operate on persistent (global) vars.
#   -v
#     Make `set` echo the value it stored instead of the var's name.
#
# ARGUMENTS:
#   1 COMMAND
#     get     -- Print a var. Exits 1 if it isn't set.
#     set     -- Assign a var.
#   2 VAR @vars
#   3 VALUE

(use hey)
(use hey/cmd)
(import hey/vars)

(defn- var-name [args]
  (or (first args) (abort "No variable specified")))

(defcmd vars [_ cmd & args &opts global? -g value? -v]
  (case cmd
    "get" (let [val (vars/get (var-name args) global?)]
            (if (nil? val) (exit 1) (echo val)))
    "set" (let [key (var-name args)
                val (get args 1)]
            (vars/set key val global?)
            (echo (if value? val key)))
    # As strings, or echo eats them: it reads leading keywords as its own
    # style flags, and every var name arrives as one.
    nil   (echo ;(map string (vars/list global?)))
    (abort "No such vars command: %s" cmd)))
