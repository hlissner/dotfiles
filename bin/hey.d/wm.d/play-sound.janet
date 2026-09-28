#!/usr/bin/env janet
# Plays a notification sound.
#
# SYNOPSIS:
#   hey wm play-sound [-v VOLUME] [-w] NAME
#   hey wm play-sound ls
#
# DESCRIPTION:
#   NAME is a sound event, looked up the way Noctalia looks one up: in the `hey`
#   sound theme (`hey path assets sounds`, linked into $XDG_DATA_HOME/sounds),
#   then whatever it inherits, then freedesktop's. A name with no sound of its
#   own sheds trailing -parts until one matches, so notify-foo plays notify.
#
# OPTIONS:
#   -v VOLUME
#     Play at VOLUME rather than the default.
#   -w
#     Block until the sound is done playing.
#
# ARGUMENTS:
#   1 NAME
#     ls    -- List the available sounds instead of playing one.

(use hey)
(import hey/sys)

(defcmd play-sound [_ name &opts volume [-v volume] wait? -w]
  (case name
    nil (usage)
    "ls" (each name (sys/sounds) (echo name))
    (match (sys/play-sound name :volume volume :wait wait?)
      nil (abort "Unrecognized sound: %s" name)
      (code (number? code)) (exit code))))
