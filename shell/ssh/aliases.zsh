key="/keybase/private/$USER/id_rsa"

config="-o UserKnownHostsFile='$XDG_CONFIG_HOME/ssh/known_hosts' -o IdentityFile='$key'"
[[ -f $XDG_CONFIG_HOME/ssh/config ]] && config="$config -F'$XDG_CONFIG_HOME/ssh/config"

alias ssh="ssh $config "
alias scp="scp -o GlobalKnownHostsFile=/etc/hosts $config "
alias ssh-copy-id="ssh-copy-id -i $key"
alias ssha="ssh-add $key"
