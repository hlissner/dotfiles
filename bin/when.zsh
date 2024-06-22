#!/usr/bin/env zsh
# Show the duration since/until $1 in a human readable format.
#
# For example: 4h 25m 55s. If given a file, its mtime is used.
#
# SYNOPSIS:
#   when DATETIME
#
# EXAMPLES:
#   hey .when 2005-05-15
#     -19y 23d 8hr 31min
#   hey .when 70sec
#     3hr 38min
#
# DEPENDENCIES:
#   timedatectl
#   dateadd, datediff (in nixpkgs.dateutils)

_read_arg() {
  if [[ "$1" =~ ^[a-zA-Z+-] ]]; then
    echo "$1"
  else
    # If given a file, give time since last modification
    [[ -e "$1" ]] && arg=reference || arg=date
    date --$arg="$1" +"%Y-%m-%dT%H:%M:%S"
  fi
}

_tz() {
  timedatectl show | grep Timezone= | cut -d= -f2
}

main() {
  local -a args=()
  for arg in $@; do
    args+=$(_read_arg "$arg")
  done
  if [[ $1 == [+-]* ]] || (( $# == 1 )); then
    args=( now ${args[@]} )
  fi
  if [[ ${args[2]} = [+-]* ]]; then
    dateadd --zone="$(_tz)" "${args[@]}"
  else
    result="$(hey.do -! -p dateutils datediff -f "%y:%m:%d:%H:%M" "${args[@]}")"
    parts=( ${(@s/:/)result} )
    (( parts[1] == 0 )) || echo -n "${parts[1]}y "
    (( parts[2] == 0 )) || echo -n "${parts[2]}m "
    (( parts[3] == 0 )) || echo -n "${parts[3]}d "
    (( parts[4] == 0 )) || echo -n "${parts[4]}hr "
    (( parts[5] == 0 )) || echo -n "${parts[5]}min "
    echo
  fi
}

if (( $# == 0 )); then
  hey.error -h "Time argument required"
  exit 1
fi

main $@
