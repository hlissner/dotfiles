#!/usr/bin/env janet
# Push my working copy of this flake at SYSTEM.
#
# SYNOPSIS:
#   heyops sync SYSTEM [RSYNC-ARGS...]
#
# DESCRIPTION:
#   rsyncs $DOTFILES_HOME over whatever SYSTEM keeps its own in -- which it gets
#   asked for rather than assumed, since the two don't have to agree.
#
#   Everything git ignores stays behind, both the repo's .gitignore and my
#   global one, and --delete means the far end ends up matching this one rather
#   than merely containing it.
#
#   Extra arguments go to rsync, so -n is there for when I don't trust myself.
#
#   REQUIRES: rsync, ssh
#
# ARGUMENTS:
#   1 SYSTEM @hosts
#   ** ARGS @default

(use hey)
(use hey/cmd)
(use sh)
(import hey/ops)

# Raw arguments, so rsync's own clustered flags arrive as it wrote them.
(defcmd sync [_ & _ argv]
  (def [system & args] (slice argv 1))
  (unless system (usage))

  (def dest (get (ops/check system) :path ""))
  (when (empty? dest)
    (abort "%s wouldn't say where its dotfiles live" system))

  # The absolute path as a dir-merge rule looks wrong and isn't: rsync goes
  # looking for that name in every directory it descends, finds the one file
  # each time, and my global ignores end up applying everywhere. Same set
  # bin/lab.d/rcp uses.
  (unless (do? $? rsync -rltDzPJ
                "--include=.git/"
                ,(string "--filter=:- .gitignore")
                ,(string "--filter=:- " (path/xdg :config "git/ignore"))
                --delete --delete-after
                ,;args
                ,(string (path :home) "/")
                ,(string system ":" dest "/"))
    (exit 1)))
