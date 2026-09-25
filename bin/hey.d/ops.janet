#!/usr/bin/env janet
# Manage remote HeyOS machines.
#
# SYNOPSIS:
#   hey ops COMMAND [ARGS...]
#
# DESCRIPTION:
#   Commands meant for managing remote NixOS systems that are built from these
#   dotfiles. Workstations only; anywhere else they refuse to run, though their
#   help is still there to read.

(use hey)

(import ./ops.d/edit)
(import ./ops.d/info)
(import ./ops.d/push)
(import ./ops.d/push-keys)
(import ./ops.d/ssh)
(import ./ops.d/sync)

(defcmd [ops :rules] [& args]
  (unless (= "workstation" (ignore-errors (flake/info :profiles :role)))
    (abort "hey ops is only available on workstations"))
  [:edit      edit/edit
   :info      info/info
   :push      push/push
   :push-keys push-keys/push-keys
   :ssh       ssh/ssh
   :sync      sync/sync])
