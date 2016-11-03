alias ls="${aliases[ls]:-ls} --color=auto"

alias open='xdg-open'

alias sys='systemctl'
alias sys!='sudo systemctl'

alias pac='pacaur'
alias pacu='pacaur -Syu'  # upgrade
alias pacc='pacaur -Sc'   # clean
alias paco='pacaur -Qtdq' # orphaned packages

if (( $+commands[xclip] )); then
    alias y='xclip -selection clipboard -in'
    alias p='xclip -selection clipboard -out'
elif (( $+commands[xsel] )); then
    alias y='xsel --clipboard --input'
    alias p='xsel --clipboard --output'
fi
