alias ls="${aliases[ls]:-ls} --color=auto --group-directories-first"

alias kb=keybase
alias sc=systemctl
alias jc=journalctl
alias ssc='sudo systemctl'
alias ufw='sudo ufw'

alias yayc='yay -Sc'    # clean pacman
alias yayo='yay -Qtdq'  # orphaned packages

alias reboot='sudo systemctl reboot'
alias shutdown='sudo systemctl poweroff'

# Clipboard pipes
if _is_callable xclip; then
  alias y='xclip -selection clipboard -in'
  alias p='xclip -selection clipboard -out'
elif _is_callable xsel; then
  alias y='xsel -i --clipboard'
  alias p='xsel -o --clipboard'
fi
