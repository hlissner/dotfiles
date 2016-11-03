#!/usr/bin/env bash

# No wifi interface? Abort!
ints=$(awk -F "/" 'FNR==NR { wire[$5]++; next  } { split(FILENAME, state, "/"); if (state[5] in wire && $1 == "up") print state[5]  }' <(find /sys/class/net/*/wireless -type d) $(find /sys/class/net/*/operstate ! -type d))
[ -z "$ints" ] && echo "Ix" && exit

# Start watching
while :
do
    signal=$(awk 'NR==3 {print $3}' /proc/net/wireless)
    echo "I${signal%?}"
    # echo "I${signal%?},$(iwgetid --raw)"
    sleep 5
done
