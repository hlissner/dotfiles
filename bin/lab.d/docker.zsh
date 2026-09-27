#!/usr/bin/env zsh
# Talk to docker on my NAS over ssh.
#
# SYNOPSIS:
#   lab docker [ARGS...]
#   lab docker ssh CONTAINER [CMD...]
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
local -a docker=(
  ssh $tty
  -o ControlMaster=auto
  -o ControlPersist=10m
  -o ControlPath="${XDG_RUNTIME_DIR:-/tmp}/ssh-%C"
  root@nas0.lan docker
)

case $1 in
  (ssh)
    local -a cmd=( "${@[3,-1]}" )
    (( $#cmd )) || cmd=( bash )
    set -- exec -i${tty:+t} "$2" "${cmd[@]}"
    ;;
  (__complete)
    # Docker won't list a subcommand it doesn't have, so I slip it into the
    # menu myself, just ahead of the directive.
    if (( $# == 2 )) && [[ ssh == ${(b)2}* ]]; then
      local -a out=( "${(@f)$($docker "${(@q)@}")}" )
      [[ $out[-1] == :<-> ]] &&
        out[-1,-1]=( $'ssh\tOpen a shell in a running container' $out[-1] )
      print -rl -- "${out[@]}"
      return
    fi
    # Past the word itself, exec already knows which containers are running.
    [[ $2 == ssh ]] && argv[2]=exec
    ;;
esac

exec $docker "${(@q)@}"
