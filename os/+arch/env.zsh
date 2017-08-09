path=(~/.local/bin $path)

export BROWSER=firefox
[[ -f ~/.ssh/agentenv ]]   && source ~/.ssh/agentenv
[[ -f ~/.gnupg/agentenv ]] && source ~/.gnupg/agentenv
