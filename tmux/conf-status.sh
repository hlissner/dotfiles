#!/usr/bin/env bash

color() { echo "#[$1=$2]"; }

HOSTNAME=$(hostname)
RESET='#[default]'

if [[ "$1" == "left" ]]
then
    FG=white
    [[ -n "$SSH_CONNECTION" ]] && FG=black

    STATUS=$(color fg $FG)' '$(tmux display-message -p '#S')
else
    if [[ -z "$SSH_CONNECTION" ]]; then
        DELIM=$(color fg yellow)
        SYSINFO=$(color fg colour246)
        IP=$(color fg white)
        HOST=$(color bg yellow)$(color fg black)
    else
        DELIM=$(color fg black)
        SYSINFO=$(color fg black)
        IP=$(color fg black)
        HOST=$(color bg black)$(color fg yellow)
    fi

    STATUS="$DELIM<<$RESET"
    STATUS+=$SYSINFO
    command -v 'tmux-mem-cpu-load' >/dev/null && STATUS+=' '$(tmux-mem-cpu-load -i 5)
    STATUS+=$RESET
    STATUS+="$DELIM < $RESET"
    STATUS+=$IP
    STATUS+=$(dig +short myip.opendns.com @208.67.222.222)
    STATUS+=' '$RESET$HOST' '
    STATUS+=$HOSTNAME
fi

echo $STATUS
