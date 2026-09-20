#!/usr/bin/env zsh
# Install this flake onto a freshly partitioned disk.
#
# SYNOPSIS:
#   install.zsh [--root DIR] [--host NAME] [--user NAME]
#   curl -sL https://raw.githubusercontent.com/hlissner/dotfiles/master/install.zsh | zsh
#
# DESCRIPTION:
#   Run this from the nixos installer once the target is partitioned and mounted
#   at /mnt.
#
#     zsh <(curl -s https://raw.githubusercontent.com/hlissner/dotfiles/refs/heads/master/install.zsh)
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
  >&2 print -r -- "Error: $*"
  exit $code
}

_usage() {
  if [[ -r ${ZSH_SCRIPT:-} ]]; then
    >&2 sed -n '2,/^$/{/^#/!d; s/^# \?//; p}' "$ZSH_SCRIPT"
  else
    >&2 print -r -- "Usage: install.zsh [--root DIR] [--host NAME] [--user NAME]"
  fi
}

_escape() {
  local str=${1//\\/\\\\}
  print -rn -- "${str//\"/\\\"}"
}

_variant() {
  ( . /etc/os-release 2>/dev/null; print -r -- "${VARIANT_ID-}" )
}

_hosts() {
  print -r -- "${(j: :)${(f)"$(ls "$1/hosts")"}}"
}

_cache_options() {  # FLAKE HOST
  # Catch 22: nix.settings only reaches /etc/nix/nix.conf after the first build,
  # so nixos-install builds the world, so we read the nix config AOT and
  # proactively inform nixos-install of those substitutors.
  local line
  nix eval --impure --raw --no-warn-dirty "$1#nixosConfigurations.$2.config.nix.settings" \
      --apply 's: builtins.concatStringsSep "\n" (builtins.filter (l: l != "") (map (n: let v = s.${n} or []; in if v == [] then "" else "extra-${n} " + builtins.concatStringsSep " " v) [ "substituters" "trusted-public-keys" ]))' \
    | while IFS= read -r line; do
        [[ $line == *' '?* ]] || continue
        print -r -- --option
        print -r -- "${line%% *}"
        print -r -- "${line#* }"
      done
  (( pipestatus[1] == 0 )) \
    || >&2 print -r -- "Warning: couldn't read nix.settings off the flake; installing without its caches"
}

_ask() {  # VAR PROMPT [DEFAULT]
  local var=$1 prompt=$2 default=$3 answer
  [[ -c /dev/tty ]] || _die 2 "nothing to ask on; pass --$var"
  read -r "answer?$prompt${default:+ [$default]}: " < /dev/tty \
    || _die 2 "no answer for --$var"
  typeset -g $var="${answer:-$default}"
  [[ -n ${(P)var} ]] || _die 2 "--$var can't be empty"
}

main() {
  local -a args
  local arg
  for arg in "$@"; do
    if [[ $arg == --*=* ]]; then
      args+=( "${arg%%=*}" "${arg#*=}" )
    else
      args+=( "$arg" )
    fi
  done
  set -- "${args[@]}"

  local -a o_user o_host o_root o_help
  zparseopts -D -F -- -user:=o_user -host:=o_host -root:=o_root \
                      h=o_help -help=o_help || { _usage; exit 2 }
  (( $#o_help )) && { _usage; exit 0 }

  local root="${o_root[2]:-/mnt}"
  local host="${o_host[2]}"
  local user="${o_user[2]}"
  local flake="$root$DEST"

  (( EUID == 0 )) || _die 1 "must be run as root"
  if [[ "$(_variant)" != installer ]]; then
    _die 1 "this isn't the nixos installer, and I'd rather not install over a live system"
  fi
  if ! mountpoint -q "$root"; then
    _die 1 "nothing is mounted at $root -- partition and mount the target first"
  fi

  if [[ -d $flake/.git ]]; then
    print -r -- "Using the clone already at $flake"
  else
    rm -rf "$flake"
    git clone --recursive "$REPO" "$flake" || _die 1 "couldn't clone $REPO"
  fi

  [[ -n $host ]] || {
    print -r -- "Hosts in this flake: $(_hosts "$flake")"
    _ask host Hostname
  }
  if [[ ! -d "$flake/hosts/$host" ]]; then
    _die 2 "no config for '$host' (this flake has: $(_hosts "$flake"))"
  fi
  [[ -n $user ]] || _ask user Username hlissner

  chown -R "${user}:users" "$flake" 2>/dev/null \
    || >&2 print -r -- "Warning: couldn't chown $flake to $user; fix it after first boot"

  [[ -e $DEST && ! -L $DEST ]] && _die 1 "$DEST already exists and isn't a symlink"
  ln -sfn "$flake" "$DEST"

  export HEYENV="{\"user\":\"$(_escape "$user")\",\"host\":\"$(_escape "$host")\",\"path\":\"$DEST\"}"
  local -a cache_opts
  cache_opts=(${(f)"$(_cache_options "$flake" "$host")"})
  nixos-install --impure --show-trace --root "$root" --flake "$flake#$host" "${cache_opts[@]}"
}

set -e
main "$@"
