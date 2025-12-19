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
    --delete \
    --delete-after \
    "$@"
}


if [[ "$(whoami)" != hlissner ]]; then
  >&2 echo "Must be hlissner!"
  exit 1
fi

set -e
case "${1:-$(hostname)}" in
  udon)
    hey.do rcp ~/projects/ /media/backup/nas0/hlissner/projects/

    if nc -w 2 -z ramen.lan 22 2>/dev/null; then
      hey.do rcp ~/projects/ ramen.lan:~/projects/
    else
      >&2 echo "Couldn't connect to ramen.lan"
    fi

    if nc -w 2 -z nas0.lan 22 2>/dev/null; then
      hey.do rcp ~/projects/ nas0.lan:~/files/projects/
      # Update local backups
      hey.do rcp nas0.lan:/mnt/nas/backup/files/ /media/backup/nas0/apps/
      hey.do rcp nas0.lan:~/files/ /media/backup/nas0/hlissner/
    else
      >&2 echo "Couldn't connect to nas0.lan"
    fi

    if nc -w 2 -z soba.lan 22 2>/dev/null; then
      if ssh soba.lan test -f ~/Media/backup1/.backup; then
        hey.do rcp /media/backup/nas0/hlissner/photos/ soba.lan:~/Media/backup1/photos/
      fi
      if ssh soba.lan test -f ~/Media/backup0/.backup; then
        hey.do rcp /media/backup/nas0/hlissner/ soba.lan:~/Media/backup0/
      fi
    else
      >&2 echo "Couldn't connect to soba.lan"
    fi
    ;;

  *)
    if ! nc -w 2 -z udon.lan 22 2>/dev/null; then
      >&2 echo "Can't connect to udon.lan"
      exit 1
    fi
    hey.do rcp ~/projects/ udon.lan:~/projects/
    ;;
esac

hey.echo -c green "✓ Done"
