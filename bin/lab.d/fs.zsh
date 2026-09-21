#!/usr/bin/env zsh
# Mount a remote over sshfs and open a shell inside it.
#
# SYNOPSIS:
#   lab fs [user@]host[:/remote/path] [subpath]
#
# DESCRIPTION:
#   Mounts a remote over sshfs, drops you into a login shell within it, and
#   tears down the mount when that shell exits.
#
#     lab fs root@example.org              # remote / at a temp mountpoint
#     lab fs root@example.org:/mnt/apps    # mount only /mnt/apps
#     lab fs root@example.org /root        # mount /, but start the shell in /root
#
# ARGUMENTS:
#   1 REMOTE @ssh-target
#   2 SUBPATH

set -u

if (( $# == 0 )); then
  >&2 echo "usage: ${0##*/} [user@]host[:/remote/path] [subpath]"
  exit 64
fi

remote=$1
subpath=${2:-}
# Default the remote path to / so `lab fs host` behaves like `ssh host`.
[[ $remote == *:* ]] || remote="${remote}:/"

host=${${remote%%:*}##*@}
mnt=$(mktemp -d "${TMPDIR:-/tmp}/sshfs-${host}.XXXXXX") || exit 1
mounted=0

cleanup() {
  local rc=$?
  # Leave the mount before unmounting it, otherwise it's an open ref to the
  # filesystem, which prevents unmounting.
  cd /
  if (( mounted )); then
    echo "Unmounting $mnt..."
    fusermount3 -u "$mnt" 2>/dev/null \
      || fusermount -u "$mnt" 2>/dev/null \
      || umount "$mnt" 2>/dev/null \
      || {
        # Something inside the mount is still running, so just detach it for
        # now. The kernel will deal with it later. Hopefully.
        >&2 echo "WARNING: $mnt is busy, detaching lazily"
        fusermount3 -uz "$mnt" 2>/dev/null || umount -l "$mnt" 2>/dev/null
      }
  fi
  rmdir "$mnt" 2>/dev/null
  return $rc
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Mounting $remote at $mnt..."
if ! sshfs "$remote" "$mnt" \
  -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,idmap=user,follow_symlinks
then
  >&2 echo "sshfs failed to mount $remote"
  exit 1
fi
mounted=1

# sshfs can return 0 having daemonized without the mount being usable.
if ! mountpoint -q "$mnt"; then
  >&2 echo "$mnt is not a mountpoint after sshfs returned success"
  exit 1
fi

target=$mnt
if [[ -n $subpath ]]; then
  target=$mnt/${subpath#/}
  if [[ ! -d $target ]]; then
    >&2 echo "no such directory on remote: ${subpath}"
    exit 1
  fi
fi

cd "$target" || exit 1

# Exported so a prompt or precmd hook can show that this shell is remote
export SSHFS_MOUNT=$mnt
export SSHFS_REMOTE=$remote

echo "Entering shell in $target -- exit or ^D to unmount."
zsh -l
rc=$?

exit $rc
