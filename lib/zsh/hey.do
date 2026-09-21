#!/usr/bin/env zsh
# hey.do [ ( -o [[-e EXE]...]) |
#           ( -! [[-p PACKAGE]...] [[--keep VAR]...] ) ]
#        COMMAND [ARGS...]
#
# Runs COMMAND, announcing it under HEYDEBUG and skipping it under HEYDRYRUN.
#
# ENVIRONMENT VARIABLES:
#   HEYDEBUG
#     If non-empty, the command and arguments will be emitted to stderr before
#     executing them.
#   HEYDRYRUN
#     If non-empty, the command and arguments will be emitted to stdout instead
#     of executed.
#
# OPTIONS:
#   -o [[-e EXE]...]
#     Makes the command no-op if COMMAND isn't in $PATH. -e can be used to
#     provide explicit executables to check against (instead of COMMAND).
#   -! [[-p PACKAGE]...] [[--keep VAR]...] )
#     Run COMMAND in cached-nix-shell, provisioning it there. Use -p to specify
#     package names explicitly (instead of COMMAND), and --keep to allow certain
#     environment variables to persist into the nix-shell session.

case $1 in
  -o)
    shift
    local -a exes
    local _ exe
    zparseopts -D -- e+:=exes
    (( $#exes == 0 )) && exes=( -e "$1" )
    for _ exe in "${exes[@]}"; do
      if ! command -v $exe >/dev/null; then
        hey.log -2 "$exe absent, skipping: $ $*"
        return 1
      fi
    done
    ;;
  -!)
    shift
    local -a pkgs keep
    zparseopts -D -- p+:=pkgs keep+:=keep
    (( $#pkgs == 0 )) && pkgs=( -p "$1" )
    # --run takes one string that the shell re-parses, so each argument has to
    # survive a round trip through quoting.
    cached-nix-shell "${keep[@]}" "${pkgs[@]}" --run "${(j: :)${(q)@}}"
    return
    ;;
esac

HEYDEBUG=${HEYDEBUG:-${HEYDRYRUN:+1}} hey.log -c green "$" "$*"
[[ ${HEYDRYRUN:-} ]] || "$@"
