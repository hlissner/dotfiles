#!/usr/bin/env janet
# Reload running services.
#
# SYNOPSIS:
#   reload [-w|--wm] [-n|--nixos]
#
# DESCRIPTION:
#   TODO
#
# OPTIONS:
#   TODO

(use hey)
(use hey/cmd)
(import hey/sys)

(defcmd reload [_]
  (echof :g "Reloading %s..." (os/getenv "XDG_CURRENT_DESKTOP"))
  (when (hey! hook reload -f -v)
    (sys/notify "Finished reloading system" :icon 'checkmark :sound 'notify))
  (echo :check "Done!"))
