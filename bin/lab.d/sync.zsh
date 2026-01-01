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
  hey.echo -c green "# Pushing $1 to $2"
  hey.do rsync -azPJ \
    --include=.git/ \
    --filter=':- .gitignore' \
    --filter=":- $XDG_CONFIG_HOME/git/ignore" \
    "$@"
}

function rcpd {
  rcp "$@" --delete --delete-during
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
    hey.do rcpd ~/projects/ /media/backup/nas0/hlissner/projects/

    if available-host ramen.lan; then
      hey.do rcpd ~/projects/ ramen.lan:~/projects/
    else
      hey.error "Couldn't connect to ramen.lan"
    fi

    if available-host nas0.lan; then
      hey.do rcpd ~/projects/ nas0.lan:~/files/projects/
      # Update local backups
      hey.do rcpd nas0.lan:/mnt/nas/backup/files/ /media/backup/nas0/apps/
      hey.do rcpd nas0.lan:~/files/ /media/backup/nas0/hlissner/
    else
      hey.error "Couldn't connect to nas0.lan"
    fi
    ;;

  ramen)
    if ! available-host udon.lan; then
      hey.error "Can't connect to udon.lan"
      exit 1
    fi
    hey.do rcpd ~/projects/ udon.lan:~/projects/

    if available-host nas0.lan; then
      hey.do rcpd ~/projects/ nas0.lan:~/files/projects/
    else
      hey.error "Couldn't connect to nas0.lan"
    fi
    ;;

  soba)
    if available-host nas0.lan; then
      hey.do rcpd nas0.lan:~/files/photos/ ~/Media/backup1/photos/
      hey.do rcpd nas0.lan:~/files/ ~/Media/backup0/
    else
      hey.error "Couldn't connect to nas0.lan"
    fi
    ;;

  htpc)
    if available-host nas0.lan; then
      for category in audiobooks books anime documentaries movies tv; do
        rcp "root@nas0.lan:/mnt/nas/media/$category/" "$HOME/jellyfin/$category/"
      done
      ssh root@nas0.lan "rsync -azPJ /mnt/nas/media/music/ /mnt/nas/users/hlissner/files/music/unsorted/"
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
