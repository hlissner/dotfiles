alias rate=mpd-rate
alias mpcs='mpc search any'
alias mpcsp='mpc searchplay any'

if [[ $OSTYPE == darwin* ]]; then
    alias mpd="mpd $XDG_CONFIG_HOME/mpd/mpd.conf"
fi
