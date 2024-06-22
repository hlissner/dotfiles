#!/usr/bin/env zsh
# hey.do [ ( -o [[-e EXE]...]) |
#           ( -! [[-p PACKAGE]...] [[--keep VAR]...] ) ]
#        COMMAND [ARGS...]
#
# TODO
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
#     If COMMAND isn't in $PATH, run the command in cached-nix-shell and try to
#     automatically provision them. Use -p to specify package names explicitly
#     (instead of COMMAND), and --keep to allow certain environment variables to
#     persist into the nix-shell session.

case $1 in
  -o)
    shift
    zparseopts -D -- e+:=exes
    (( $#exes == 0 )) && exes=( -e "$1" )
    for _ exe in ${exes[@]}; do
      if ! command -v $exe >/dev/null; then
        hey.log -2 "$exe absent, skipping: $ $@"
        exit 1
      fi
    done
    ;;
  -!)
    shift
    zparseopts -D -- p+:=pkgs keep+:=keep
    (( $#pkgs == 0 )) && pkgs=( -p "$1" )
    cached-nix-shell ${keep[@]} ${pkgs[@]} --run "$*"
    exit
    ;;
esac

HEYDEBUG=${HEYDEBUG:-${HEYDRYRUN:+1}} hey.log -c green "$" "$*"
[[ $HEYDRYRUN ]] || $@
