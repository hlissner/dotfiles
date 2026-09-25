#!/usr/bin/env zsh
# Talk to docker on my NAS over ssh.
#
# SYNOPSIS:
#   lab docker [ARGS...]
#   lab dk [ARGS...]
#
# DESCRIPTION:
#   Forwards arguments to docker on root@nas0.lan. Comes with lovely zsh
#   completion which makes the *chef kiss*.
#
# ARGUMENTS:
#   ** ARGS @cobra

local -a tty
# A pty on a pipe turns newlines into CRLFs and folds stderr into stdout, which
# breaks `lab dk logs x | grep` and TAB completion alike.
[[ -t 0 && -t 1 ]] && tty=( -t )

# Every TAB would've been round-trip through here. Persist the connection to
# make this fast.
exec ssh $tty \
  -o ControlMaster=auto \
  -o ControlPersist=10m \
  -o ControlPath="${XDG_RUNTIME_DIR:-/tmp}/ssh-%C" \
  root@nas0.lan docker "${(@q)@}"
