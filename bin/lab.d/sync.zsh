#!/usr/bin/env zsh
#
# Backup all personal files to several locations.
#
# I switch between workstations for different workloads. Timing issues and diff
# conflicts make automated solutions (like syncthing or rclone/rsyncing on a
# cronjob) unreliable and opaque, so I opt for a script to manually sync them on
# demand, which seconds as a backup script (to my NAS).
#
# SYNOPSIS:
#   $0

function rcp {
  echo
  hey.echo -c green "# Pushing $1 to ${@[2,-1]}"
  if [[ $1 == nas0.lan:* ]]; then
    # nas0.lan can never have fd installed, so use rsync directly there, which
    # is safe because only filtered backups make it to nas0 anyway.
    hey.do rsync -azPJ --delete --delete-after "$@"
  else
    hey.do lab rcp -a "$@"
  fi
}

function available-host {
  nc -w 2 -z "$1" 22 2>/dev/null
}


if [[ "$(whoami)" != hlissner ]]; then
  hey.error "Must be hlissner!"
  exit 1
fi

set -e
local host=$(hostname)
case $host in
  udon)
    # One rcp for all of them: the fd walk of ~/projects is the slow part, and
    # it only depends on the source.
    local -a dsts=( /media/backup/nas0/hlissner/projects/ )
    if available-host ramen.lan; then
      dsts+=( 'ramen.lan:~/projects/' )
    else
      hey.error "Couldn't connect to ramen.lan"
    fi
    local nas0=
    if available-host nas0.lan; then
      nas0=1
      dsts+=( 'nas0.lan:~/files/projects/' )
    fi
    rcp ~/projects/ "${dsts[@]}"

    if [[ $nas0 ]]; then
      # Update local backups
      rcp nas0.lan:/mnt/nas/backup/files/ /media/backup/nas0/apps/
      rcp nas0.lan:~/files/ /media/backup/nas0/hlissner/
    else
      hey.error "Couldn't connect to nas0.lan"
    fi

    if available-host soba.lan; then
      if ssh soba.lan test -s ~/Media/external; then
        rcp /media/backup/nas0/hlissner/ soba.lan:~/Media/external
      fi
    else
      hey.error "Couldn't connect to soba.lan"
    fi
    ;;

  ramen)
    if ! available-host udon.lan; then
      hey.error "Can't connect to udon.lan"
      exit 1
    fi
    local -a dsts=( 'udon.lan:~/projects/' )
    if available-host nas0.lan; then
      dsts+=( 'nas0.lan:~/files/projects/' )
    else
      hey.error "Couldn't connect to nas0.lan"
    fi
    rcp ~/projects/ "${dsts[@]}"
    ;;

  soba)
    if available-host nas0.lan; then
      if [[ -f ~/Media/backup0/.backup ]]; then
        rcp nas0.lan:~/files/ ~/Media/backup0/
        if [[ -f ~/Media/backup1/.backup ]]; then
          rcp ~/Media/backup0/ ~/Media/backup1/
        fi
      fi
    else
      hey.error "Couldn't connect to nas0.lan"
    fi
    ;;

  *)
    hey.error "Unknown host: $host"
    exit 1
    ;;
esac

hey.echo -c green "✓ Done"
