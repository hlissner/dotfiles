#!/usr/bin/env janet
# Enable given monitors and disable the rest.
#
# SYNOPSIS:
#   hey wm set-monitors [--on|--off] [OUTPUTS...]
#   hey wm set-monitors HDMI-A-1
#
# DESCRIPTION:
#   Why not just leave it to the compositor's config? Because it has trouble
#   with a monitor I want known but off at startup (the TV), and a keybind that
#   says "just this one" is easier than editing anything. Hosts wrap this with
#   their own shorthands (hosts/udon/bin/set-monitors.zsh).
#
# OPTIONS:
#   --on
#     Only activate the given displays (i.e. don't disable the rest).
#   --off
#     Only deactivate the given displays (i.e. don't enable the rest).

(use hey)
(import hey/wm)
(import hey/sys)

(defn- known
  "Every real output; the compositor's placeholders aren't mine to toggle."
  []
  (filter |(not (string/has-prefix? "Unknown" ($0 :name))) (wm/outputs)))

(defcmd set-monitors [_ & names &opts on? --on off? --off]
  (when (and on? off?) (usage))
  (when (empty? names) (usage))
  (def to-enable (if off? [] names))
  (def to-disable
    (cond off? names
          on? []
          (seq [o :in (known) :unless (index-of (o :name) names)] (o :name))))
  (log 2 "enable: %q; disable: %q" to-enable to-disable)
  (each name to-enable (wm/set-output name true))
  (each name to-disable (wm/set-output name false))
  (sys/toast :info (string "Set monitors: " (string/join names " "))))
