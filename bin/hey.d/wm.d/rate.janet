#!/usr/bin/env janet
# Rate the track playing in Supersonic.
#
# SYNOPSIS:
#   hey wm rate 1|2|3|4|5
#   hey wm rate favorite
#
# DESCRIPTION:
#   Only when Supersonic is the focused window; otherwise this does nothing.
#   niri's binds can't pass a keystroke on to whatever else was focused, so
#   SUPER+CTRL+1..6 are dead everywhere but Supersonic.
#
# ARGUMENTS:
#   1 RATING
#     1 -- One star.
#     2 -- Two.
#     3 -- Three.
#     4 -- Four.
#     5 -- Five.
#     favorite -- Toggle the track's favorite flag instead.

(use hey)
(use sh)
(import hey/wm)

(def- app-id "io.github.supersonic-app.supersonic")

(defcmd rate [_ rating]
  (unless (index-of rating ["1" "2" "3" "4" "5" "favorite"]) (usage))
  (when (= app-id (get (wm/focused-window) :app-id))
    (if (= rating "favorite")
      (do? $ hey "@supersonic" favorite)
      (do? $ supersonic -rate-current ,rating))))
