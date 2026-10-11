#!/usr/bin/env janet
# Open a foot terminal.
#
# SYNOPSIS:
#   hey wm open-term [-t TITLE] [-f FONT] [-F N] [-o OPT]... [FOOTARGS...] [-- TMUXARGS...]
#
# DESCRIPTION:
#   Arguments before a literal -- are passed to foot; those after it are passed
#   to tmux. With a TITLE, the terminal is named and attached to a tmux session
#   of the same name.
#
# OPTIONS:
#   -o OPT
#     Pass an option to foot (-o key=value). May be repeated.
#   -t, --title TITLE
#     Name the terminal, and attach it to a tmux session of that name.
#   -f, --font FONT
#     Use FONT instead of the configured one, as NAME or NAME:size=N.
#   -F, --font-adjust N
#     Adjust the font size by N points.

(use hey)
(use sh)

(defcmd open-term [_ & rest argv &opts opts [-o opt *]
                   title [-t --title title]
                   font [-f --font font]
                   offset [-F --font-adjust offset]]
  # defcmd swallows the -- and appends what followed it to the rest, so what
  # follows the -- in the raw argv is the tail of the rest.
  (def after (if-let [i (index-of "--" argv)] (slice argv (inc i)) []))
  (def footargs (slice rest 0 (- (length rest) (length after))))
  (def tmuxargs
    (cond title ["new" "-A" "-s" title ;after]
          (empty? after) []
          ["-c" ;after]))
  (def font (or font (flake/info :theme :fonts :mono) "JetBrainsMono Nerd Font"))
  (def [name size] (or (peg/match (peg! '(* (<- (any (if-not ":" 1))) (? (* (thru "size=") (number :d+)))))
                                  font)
                       [font nil]))
  (def size (+ (or size 9) (if offset (scan-number offset) 0)))
  (do? $ foot ,;(if title ["-T" title] [])
              ,;footargs
              -o ,(fmt "main.font=%s:size=%d" name size)
              ,;(mapcat |["-o" $0] (or opts []))
              "--" tmux ,;tmuxargs))
