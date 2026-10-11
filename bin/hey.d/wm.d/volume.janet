#!/usr/bin/env janet
# Nudge the volume to the next multiple of ten.
#
# SYNOPSIS:
#   hey wm volume [-s STEP] sink|player up|down
#
# DESCRIPTION:
#   Snaps to the nearest multiple of STEP in the direction asked, rather than
#   adding STEP: 43 goes up to 50 and down to 40. OCD-maxxing. The sink is set
#   through Noctalia so its OSD shows; the player through playerctl.
#
# OPTIONS:
#   -s STEP
#     Snap to multiples of STEP instead of 10.
#
# ARGUMENTS:
#   1 TARGET
#     sink    -- The default PipeWire sink.
#     player  -- The active MPRIS player.
#   2 DIRECTION
#     up
#     down

(use hey)
(use sh)

(defn snap
  "The next multiple of STEP from V in DIR, clamped to 0..100."
  [v dir &opt step]
  (default step 10)
  (-> (if (= dir "up")
        (+ (- v (% v step)) step)
        (- v (if (zero? (% v step)) step (% v step))))
      (max 0)
      (min 100)))

(defn- percent
  "The first 0..1 number in TEXT, as an integer percentage; nil if none."
  [text]
  (when-let [[v] (peg/match (peg! '(* (any (if-not (set "0123456789.") 1))
                                      (number (* :d+ (? (* "." :d+))))))
                            (string text))]
    (math/round (* v 100))))

(defcmd volume [_ target dir &opts step [-s step]]
  (unless (index-of dir ["up" "down"]) (usage))
  (def step (if step (scan-number step) 10))
  (case target
    "sink"
    (when-let [v (percent ($< wpctl get-volume "@DEFAULT_AUDIO_SINK@"))]
      (do? $ noctalia msg volume-set ,(string (snap v dir step))))

    "player"
    (when-let [v (percent ($< playerctl volume))]
      # playerctl wants 0..1; snap hands over 0..100.
      (do? $ playerctl volume ,(string (/ (snap v dir step) 100))))

    (usage)))
