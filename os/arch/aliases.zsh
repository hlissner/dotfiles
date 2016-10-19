alias ls="${aliases[ls]:-ls} --color=auto"

alias open='xdg-open'

alias pac='sudo pacman'
alias pacu='sudo pacman -Syu'

if (( $+commands[xclip] )); then
    alias y='xclip -selection clipboard -in'
    alias p='xclip -selection clipboard -out'
elif (( $+commands[xsel] )); then
    alias y='xsel --clipboard --input'
    alias p='xsel --clipboard --output'
fi
