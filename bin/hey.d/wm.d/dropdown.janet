#!/usr/bin/env janet
# Toggle a floating terminal over whatever workspace is focused.
#
# SYNOPSIS:
#   hey wm dropdown
#
# DESCRIPTION:
#   One foot window (app-id and tmux session both "dropdown"), brought to the
#   focused workspace, or dismissed if it's already there. Dismissing closes
#   the window; the tmux session keeps whatever was running, and the next
#   summon attaches to it. niri has no sticky windows, which is why this is a
#   command and not a window rule: the rule in config.kdl only floats it and
#   parks it at the top of the screen.

(use hey)
(import hey/wm)
(import ./open-term)

(def- app-id "dropdown")

(defcmd dropdown [_]
  (def w (find |(= ($0 :app-id) app-id) (wm/windows)))
  (def here (or (wm/focused-workspace) (abort "No focused workspace")))
  (def id (string (get w :id)))
  (cond
    (nil? w)
    (let [argv (open-term/foot-argv :title app-id :footargs ["-a" app-id])]
      (if (dryrun?)
        (print "DRYRUN: " (string/join argv " "))
        (os/spawn argv :pd)))

    (= (w :workspace) (here :id))
    (wm/action "close-window" "--id" id)

    # A numeric niri reference is an index on the focused output, which is
    # where the focused workspace is.
    (let [ref (string (or (here :name) (here :idx) (here :id)))]
      (wm/action "move-window-to-workspace" "--window-id" id ref)
      (wm/action "focus-window" "--id" id))))
