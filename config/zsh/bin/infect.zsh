#!/usr/bin/env zsh
# Deploy config/zsh onto a remote host over ssh.
#
# SYNOPSIS:
#   infect [-n] HOST
#
# DESCRIPTION:
#   Deletes ~/.config/zsh and ~/.zshenv on the remote and replaces them with
#   config/zsh and config/zsh/.zshenv, respectively. The remote only needs an
#   ssh server that understands sftp (only openssh servers). Doesn't work with
#   dropbear.
#
# OPTIONS:
#   -n, --dry-run
#     Print what would be run without running it. The preflights tests still run
#     on the remote
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

  local rc
  ssh $host 'command -v zsh >/dev/null'; rc=$?
  (( rc == 255 )) && hey.abort "Can't reach $host"
  (( rc == 0   )) || hey.abort "No zsh on $host; try: hey @bash infect $host"

  # zpm execs a helper out of $ZPM_DIR to install plugins, so a noexec mount
  # there silently gets none of them forever, since it caches a no-op `zpm ()
  # {}` afterwards.
  ssh $host '
    d=${XDG_DATA_HOME:-$HOME/.local/share}
    mkdir -p "$d" || exit 0
    f=$d/.hey-exec-test.$$
    printf "#!/bin/sh\n" >"$f" && chmod +x "$f" && "$f" 2>/dev/null
    rc=$?; rm -f "$f"; exit $rc
  '; rc=$?
  if (( rc != 0 && rc != 255 )); then
    hey.warn "$host can't execute anything under \$XDG_DATA_HOME (noexec?)"
    hey.echo -c yellow "  zpm's plugins won't install. Point ZPM_DIR somewhere"
    hey.echo -c yellow "  executable, or take noexec off the mount."
  fi

  # scp only ever adds, and -r lands the staged directory *in* its destination,
  # hence ~/.config and not ~/.config/zsh.
  hey.do ssh $host 'rm -rf ~/.config/zsh ~/.zshenv && mkdir -p ~/.config' || exit $?

  # scp has no --exclude and always follows symlinks, so what gets sent is
  # shaped here instead; cp -L is what makes lib/ real files.
  local stage=$(hey path runtime infect.$$)
  trap "rm -rf ${(q)stage}" EXIT INT TERM
  if [[ ! $HEYDRYRUN ]]; then
    mkdir -p $stage &&
      cp -RL $root/config/zsh/. $stage/zsh &&
      rm -rf $stage/zsh/bin $stage/zsh/**/*.zwc(N) ||
      hey.abort "Couldn't stage the config in $stage"
  fi

  hey.do scp -rpq $stage/zsh $host:.config/ || exit $?

  # The one file that can't live under $ZDOTDIR: it's what announces $ZDOTDIR.
  hey.do ssh $host 'ln -sf .config/zsh/.zshenv ~/.zshenv' || exit $?

  [[ $dryrun ]] || hey.echo -c green "✓ Infected $host"
}

main $@
