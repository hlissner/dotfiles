#!/usr/bin/env zsh
# A simulation of the completion system, for testing lib/zsh/completions/*.
#
# SYNOPSIS:
#   completion.zsh COMPLETION CASE [WORD...]
#
# COMPLETION names a file in lib/zsh/completions, minus its leading underscore.
# CASE is one of the arms at the bottom. WORDs become $words, spelled the way
# zsh spells them: the whole command line, *including* the word being completed,
# which is usually the empty one at the end. $CURRENT points at it.

emulate -L zsh
# What compinit's _comp_setup guarantees for any real completion.
setopt extendedglob nullglob bareglobqual rcexpandparam unset
setopt no_globsubst no_shwordsplit
local -a reply  # _comp_setup declares this; see the note in _hey's header.

_arguments() { local a; for a in "$@"; do [[ $a == (-C|-A|-\*) ]] && continue; print -r -- "ARG $a"; done }
_describe()  { local t=$2 n=$4 x=$6
               print -r -- "DESC[$t] ${(j: :)${(P)n}}"
               [[ -n $x ]] && print -r -- "DESC[$t] ${(j: :)${(P)x}}"
               return 0 }
_wanted()    { local t=$1; shift 4; print -r -- "WANT[$t] ${(j: :)@}" }
_alternative() { print -r -- "ALT ${(j: :)@}" }
_default()   { print -r -- "DEFAULT" }
_files()     { print -r -- "FILES" }
_command_names() { print -r -- "COMMANDS ${(j: :)@}" }
_hosts()     { print -r -- "HOSTS ${(j: :)@}" }
_remote_files() { print -r -- "REMOTE[${IPREFIX%:}] ${(j: :)@} $PREFIX" }
compadd()    { print -r -- "ADD ${(j: :)@}" }
# globsubst because the real compset takes a pattern, and NO_glob_subst -- which
# _comp_setup sets, and which the builtin is not subject to -- would make `-P
# '*:'` a search for two literal characters.
compset()    { setopt localoptions globsubst
               local p=$@[-1] before=$PREFIX
               [[ $PREFIX == $p* ]] || return 1
               if [[ $# -ge 3 && $2 == <-> ]]; then PREFIX=${PREFIX#$p}
               else                                 PREFIX=${PREFIX##$p}
               fi
               IPREFIX+=${before[1,$#before-$#PREFIX]}
               return 0 }

local root=${0:A:h:h:h}
local completion=$1 case=$2; shift 2
# Every completion falls back to deriving this from its own path, which is not
# where it lives in a test. The shims in path/ are what `command hey` finds; see
# the note in there for why they have to come first.
local -x DOTFILES_HOME=$root
local -x PATH=$root/test/_lib/path:$PATH

# The shared half of every completion comes off $fpath, by the same glob
# modules/hey.nix autoloads it with. Sourcing the completion itself runs it on
# no arguments, which is noise, not an error.
fpath=( $root/lib/zsh $fpath )
autoload -Uz $root/lib/zsh/hey.*(.:t)
source $root/lib/zsh/completions/_$completion >/dev/null 2>&1

local -a _hey_reply _hey_cmd _hey_bindirs _hey_cfgdirs _hey_hookareas
local _hey_root=$root _hey_bin=$completion
local _hey_host _hey_wm _hey_datadir
# The name the completion was invoked for. Only a wrapper makes it interesting.
local service=$completion

# heyops refuses to run anywhere but a workstation, and asks info.json which it
# is. Without a stand-in, whether this suite can complete anything would depend
# on the role of whatever machine is running it -- green here, red on a server
# and red in CI, where info.json is `{}`.
[[ $completion == heyops ]] &&
  local -x XDG_DATA_HOME=$root/test/heyops/heyops.d/workstation

# hey is the only one that walks $DOTFILES_HOME, so it's the only one with
# anything to stand in for.
if [[ $completion == hey ]]; then
  _hey_host=testhost
  _hey_wm=testwm
  _hey_datadir=$root/test/_lib/data
  _hey_bindirs=( $root/test/_lib/bin )
  _hey_cfgdirs=( alpha beta )
  _hey_hookareas=( alpha beta host )
fi

# Report what would be dumped rather than running hey, so the command line a
# walk reconstructs is observable.
__driver_nodump() { hey.comp.dump() { print -r -- "DUMP ${(j: :)@}"; return 1 } }
__driver_nohey()  { hey.comp.scan() { return 1 }; hey.comp.dump() { return 1 } }

words=( "$@" ); CURRENT=$#words; PREFIX=""; IPREFIX=""; SUFFIX=""; line=( "$@" )
case $case in
  (dispatch) hey.comp.dispatch ;;
  (menu) PREFIX=${1-}; hey.comp.commands ;;
  (areas) PREFIX=${1-}; __hey_hook_areas ;;
  # __hey_hook_arg reads the positional that _arguments already consumed out
  # of $line, and $CURRENT as *:: leaves it: 1 for the first of the rest
  # arguments.
  (hookarg)
    __hey_hooks() { print -r -- "HOOKS ${(j: :)@}" }
    line=( ${1-} ); CURRENT=${2:-1}
    __hey_hook_arg
    ;;
  # __hey_sync_arg branches on the command _arguments already matched and counts
  # how far into the rest arguments it is, both of which it reads out of $line:
  # every positional, the word being completed included. $1 is the command.
  (syncarg)
    line=( "$@" ); words=( hey sync "$@" ); CURRENT=$#words
    __hey_sync_arg
    ;;
  # The real entry point, on its own terms: it declares its own locals, so these
  # three are the only cases that ignore the fixtures above.
  (top) _$completion ;;
  # Same, but standing in for `compdef NAME _hey`. zsh looks a completion up by
  # the command's basename, so that -- and not $words[1] -- is what $service is.
  (wrapper|wrapper-dump)
    [[ $case == wrapper-dump ]] && __driver_nodump
    # A wrapper's search path comes from _hey itself, so the fixture tree has to
    # *be* $DOTFILES_HOME for the walk to land in it.
    DOTFILES_HOME=$root/test/_lib
    service=${words[1]:t}
    _$completion
    ;;
  (reconstruct) __driver_nodump; hey.comp.dispatch ;;
  # One completer by name, for the @refs nothing else in here reaches: $1 names
  # it, $2 is the word so far.
  (call) PREFIX=${2-}; $1 ;;
  # Every path must degrade rather than error if the binary is unavailable
  (nohey) __driver_nohey; hey.comp.dispatch ;;
  (*) print -r -- "unknown case: $case"; return 2 ;;
esac
