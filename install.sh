#!/usr/bin/env bash
# Install this flake onto a freshly partitioned disk.
#
# SYNOPSIS:
#   install.sh [--root DIR] [--host NAME] [--user NAME]
#   bash <(curl -s https://raw.githubusercontent.com/hlissner/dotfiles/refs/heads/master/install.sh)
#
# DESCRIPTION:
#   Run this from the nixos installer once the target is partitioned and mounted
#   at /mnt.
#
#     bash <(curl -sL https://henrik.io/install.sh)
#
#   It clones the flake to $root/etc/dotfiles and installs it, asking for
#   anything it wasn't told.
#
# OPTIONS:
#   --root DIR
#     Where the target system is mounted. Default: /mnt
#   --host NAME
#     Which config under hosts/ to install. Asked for if omitted.
#   --user NAME
#     Primary user of the new system. Asked for if omitted.
#
# EXIT CODES:
#   1  not root, not the installer, or a command failed
#   2  bad, missing, or unanswerable argument

readonly REPO=https://github.com/hlissner/dotfiles
readonly DEST=/etc/dotfiles

_die() {  # CODE MESSAGE...
  local code=$1; shift
  >&2 echo "Error: $*"
  exit "$code"
}

_usage() {
  # Over bash <(curl ...) this is a pipe that bash has already drained.
  if [[ -f ${BASH_SOURCE[0]:-} ]]; then
    >&2 sed -n '2,/^$/{/^#/!d; s/^# \?//; p}' "${BASH_SOURCE[0]}"
  else
    >&2 echo "Usage: install.sh [--root DIR] [--host NAME] [--user NAME]"
  fi
}

_variant() {
  ( . /etc/os-release 2>/dev/null; echo "${VARIANT_ID-}" )
}

_hosts() {
  ls "$1/hosts" | paste -sd ' ' -
}

_ask() {  # VAR PROMPT [DEFAULT]
  local var=$1 prompt=$2 default=${3-} answer
  [[ -c /dev/tty ]] || _die 2 "nothing to ask on; pass --$var"
  read -r -p "$prompt${default:+ [$default]}: " answer < /dev/tty \
    || _die 2 "no answer for --$var"
  printf -v "$var" '%s' "${answer:-$default}"
  [[ -n ${!var} ]] || _die 2 "--$var can't be empty"
}

main() {
  local root=/mnt host= user=
  while (( $# )); do
    case $1 in
      --*=*) set -- "${1%%=*}" "${1#*=}" "${@:2}"; continue ;;
      --root|--host|--user)
        (( $# > 1 )) || _die 2 "$1 needs a value"
        printf -v "${1#--}" '%s' "$2"; shift ;;
      -h|--help) _usage; exit 0 ;;
      *) _usage; exit 2 ;;
    esac
    shift
  done
  local flake="$root$DEST"

  if [[ "$(_variant)" != installer ]]; then
    _die 1 "this isn't the nixos installer, and I'd rather not install over a live system"
  fi
  (( EUID == 0 )) || _die 1 "must be run as root"
  if ! mountpoint -q "$root"; then
    _die 1 "nothing is mounted at $root -- partition and mount the target first"
  fi

  if [[ -d $flake/.git ]]; then
    echo "Using the clone already at $flake"
  else
    rm -rf "$flake"
    git clone --recursive "$REPO" "$flake" || _die 1 "couldn't clone $REPO"
  fi

  [[ -n $host ]] || {
    echo "Hosts in this flake: $(_hosts "$flake")"
    _ask host Hostname
  }
  if [[ ! -d "$flake/hosts/$host" ]]; then
    _die 2 "no config for '$host' (this flake has: $(_hosts "$flake"))"
  fi
  [[ -n $user ]] || _ask user Username hlissner

  chown -R "${user}:users" "$flake" 2>/dev/null \
    || >&2 echo "Warning: couldn't chown $flake to $user; fix it after first boot"

  # nixos-install doesn't have --accept-flake-config!
  nixos-install --show-trace --option accept-flake-config true \
    --root "$root" --flake "$flake#$host"
}

# Everything above only defines things, so a connection that dies halfway
# through the curl leaves nothing half-run.
set -euo pipefail
main "$@"
