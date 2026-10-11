#!/usr/bin/env janet
# Enable given monitors and disable the rest.
#
# SYNOPSIS:
#   hey wm set-monitors [--on|--off] [OUTPUTS...]
#   hey wm set-monitors HDMI-A-1
#
# DESCRIPTION:
#   Why not just leave it to the compositor's config? Because both have trouble
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
(use sh)
(import hey/wm)
(import hey/sys)

(defn- known
  "Every real output; the compositor's placeholders aren't mine to toggle."
  []
  (filter |(not (string/has-prefix? "Unknown" ($0 :name))) (wm/outputs)))

(defn- enabled? [name]
  (get (find |(= ($0 :name) name) (wm/outputs)) :enabled))

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
  # Hyprland struggles to light some displays on the first ask, and wlr-randr
  # gets through where it doesn't. Only after a beat, or it reads stale state.
  (when (and (= (wm) :hypr) (not (empty? to-enable)) (not (dryrun?)))
    (os/sleep 0.25)
    (each name to-enable
      (unless (enabled? name)
        (log 3 "wlr-randr: %s" name)
        (do? $ wlr-randr --output ,name --on))))
  (sys/toast :info (string "Set monitors: " (string/join names " "))))
