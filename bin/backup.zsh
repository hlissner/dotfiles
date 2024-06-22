#!/usr/bin/env zsh
# Push or pull projects to my NAS.
#
# I switch between workstations for different workloads. Timing issues make
# automated solutions (like dropbox, syncthing, or rclone/rsyncing on a cronjob)
# unreliable and opaque, so I opt for a script to sync with my NAS, for other
# systems to pull form.
#
# The expectation is I'd `hey .projects push` on one machine, then `hey
# .projects pull` on the next (then push+pull later, again).
#
# SYNOPSIS:
#   $0 backup [push|pull]

function rcp {
  rsync -azPJ \
    --include=.git/ \
    --filter=':- .gitignore' \
    --filter=":- $XDG_CONFIG_HOME/git/ignore" \
    --delete \
    --delete-after \
    "$@"
}

if ! mountpoint -q /media/nas; then
  >&2 echo "/media/nas isn't a mount point"
  exit 1
fi

local -A dst=()
dst[$HOME/.secrets/]=/media/nas/secrets/
dst[$HOME/projects/]=/media/nas/projects/

case "$1" in
  ''|push)
    hey.echo -c green "> Backing up projects to NAS..."
    for from to in ${(kv)dst}; do
      hey.do rcp "$from" "$to"
    done
    ;;
  pull)
    hey.echo -c green "> Pulling from NAS..."
    for to from in ${(kv)dst}; do
      hey.do rcp "$from" "$to"
    done
    ;;
  *)
    hey.error "Push or pull? That is the question..."
    exit 1
    ;;
esac

hey.echo -c green "✓ Done"
