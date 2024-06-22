#!/usr/bin/env janet
# TODO
#
# SYNOPSIS:
#   vars [get|set|ls] ...

(use hey)
(use hey/cmd)
(import hey/vars)

(defcmd vars [_ cmd & args &opts global? -g]
  (echo ;(case cmd
          "get" [(vars/get (first args) global?)]
          "set" [(vars/set ;(slice args 0 2) global?)]
          nil   (vars/list global?))))
