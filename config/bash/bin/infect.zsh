#!/usr/bin/env zsh
# Deploy config/bash onto a remote host over ssh.
#
# SYNOPSIS:
#   infect [-n] HOST
#
# DESCRIPTION:
#   Copies config/bash to HOST's ~/.config/bash and points ~/.bashrc and
#   ~/.bash_profile at it. For hosts with no zsh to infect; anywhere else wants
#   `hey @zsh infect`.
#
#   Destructive, by design: ~/.config/bash, ~/.bashrc and ~/.bash_profile are
#   deleted outright before anything is sent -- including whatever the distro
#   put there. Nothing is merged and nothing is backed up.
#
# OPTIONS:
#   -n, --dry-run
#     Print what would be run without running it. The preflight checks still run
#     on the remote.
#
# ARGUMENTS:
#   1 HOST @ssh-host

main() {
  hey.requires scp ssh
  local -a dryrun
  zparseopts -D -F -- n=dryrun -dry-run=dryrun || exit 1
  [[ $dryrun ]] && export HEYDRYRUN=1

  local host=$1
  [[ $host ]] || hey.abort "Need a host to infect"
  local root=${DOTFILES_HOME:-${0:a:h:h:h:h}}

  # Scorched earth first, so nothing the distro (or a previous me) left behind
  # survives to be sourced. ~/.config, not ~/.config/bash, because scp -r
  # lands the staged directory *in* its destination.
  hey.do ssh $host \
    'rm -rf ~/.config/bash ~/.bashrc ~/.bash_profile && mkdir -p ~/.config' ||
    exit $?

  # scp has no --exclude, so bin/ gets dropped here instead -- it's this
  # script, which needs zsh and the repo, neither of which is why we're here.
  local stage=$(hey path runtime infect.$$)
  trap "rm -rf ${(q)stage}" EXIT INT TERM
  if [[ ! $HEYDRYRUN ]]; then
    mkdir -p $stage &&
      cp -RL $root/config/bash/. $stage/bash &&
      rm -rf $stage/bash/bin ||
      hey.abort "Couldn't stage the config in $stage"
  fi

  hey.do scp -rpq $stage/bash $host:.config/ || exit $?

  hey.do ssh $host '
    ln -sf .config/bash/bashrc ~/.bashrc
    ln -sf .config/bash/profile ~/.bash_profile
  ' || exit $?

  [[ $dryrun ]] || hey.echo -c green "✓ Infected $host"
}

main $@
