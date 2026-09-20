#!/usr/bin/env zsh
# Drop the local overrides that the config files already decide.
#
# SYNOPSIS:
#   hey @noctalia reset [-n] [-a]
#
# DESCRIPTION:
#   Noctalia locks a "reset all overridden settings" button (you *can* do it per
#   page in the settings, but not everything in one sweep). I could delete
#   $XDG_STATE_HOME/noctalia/settings.toml, but that would delete more than just
#   my settings. So!
#
#   This script looks through $DOTFILES_HOME/config/noctalia/{bar,config}.toml
#   and unsets them in $XDG_STATE_HOME/noctalia/settings.json. It'll print out
#   all settings that were unset.
#
#   REQUIRES: python3 (with tomlkit)
#
# OPTIONS:
#   -n, --dry-run
#     Print the keys that would go and leave the file alone.
#   -a, --all
#     Drop the whole file, app-managed keys included. Costs the wallpaper
#     selection and both memories; nothing a relog won't pick again.

# Prints the keys it dropped, one per line, and writes the pruned document to
# OUT. Never touches OVERRIDES itself; that's the shell's call.
prune() {
  python3 - "$@" <<'EOF'
import sys
from collections.abc import MutableMapping as Mapping, MutableSequence as Sequence
from tomlkit import parse, dumps

config, overrides, out = sys.argv[1:]
with open(config) as f: decided = parse(f.read())
with open(overrides) as f: doc = parse(f.read())

# [[a.b]] and a.b = [ { ... } ] parse differently but are the same thing: an
# array of tables, which is owned whole because half of one isn't worth merging.
def is_aot(v):
    return isinstance(v, Sequence) and len(v) > 0 and isinstance(v[0], Mapping)

def stated(node, path=()):
    for k, v in node.items():
        p = path + (k,)
        if is_aot(v): yield p, True
        elif isinstance(v, Mapping): yield from stated(v, p)
        else: yield p, False

leaves, arrays = set(), set()
for p, whole in stated(decided): (arrays if whole else leaves).add(p)

def prune(node, path=()):
    for k in list(node.keys()):
        p, v = path + (k,), node[k]
        if p in arrays or (p in leaves and not isinstance(v, Mapping)):
            del node[k]
            print(".".join(p))
        elif isinstance(v, Mapping):
            prune(v, p)
            # tomlkit keeps the header of a table it emptied, which would read as
            # "the override file says this section is empty".
            if not v: del node[k]

prune(doc)
# toml++ writes no newline at EOF, and a deleted last table leaves its leading
# blank line behind; one newline, always, is what the line-based version did.
with open(out, "w") as f: f.write(dumps(doc).rstrip("\n") + "\n")
EOF
}

main() {
  set -eo pipefail
  hey.requires noctalia python3
  local -a dry all
  zparseopts -D -F -- n=dry -dry-run=dry a=all -all=all || exit 1
  # One dry-run for the flag and hey's own, so every hey.do below honours both.
  (( $#dry )) && export HEYDRYRUN=1

  local file=${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}/noctalia/settings.toml
  if [[ ! -f $file ]]; then
    hey.echo "Nothing to reset; $file doesn't exist."
    return
  fi

  if (( $#all )); then
    hey.do cp -- $file $file.bak
    hey.do rm -- $file
  else
    local scratch=$(mktemp -d)
    trap "rm -rf $scratch" EXIT
    NOCTALIA_STATE_HOME=$scratch noctalia config export merged >$scratch/config.toml
    local -a dropped
    dropped=( ${(f)"$(prune $scratch/config.toml $file $scratch/settings.toml)"} )
    if (( ! $#dropped )); then
      hey.echo -c green "Nothing overridden that the config already decides."
      return
    fi
    print -l -- $dropped
    hey.do cp -- $file $file.bak
    hey.do cp -- $scratch/settings.toml $file
  fi

  if [[ $HEYDRYRUN ]]; then
    hey.echo -c yellow "Dry run; $file is untouched."
    return
  fi
  # Noctalia watches the state dir for outside writes, but the reload is
  # debounced and this is nicer than waiting...
  hey.do noctalia msg config-reload || true
}

main "$@"
