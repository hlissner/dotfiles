alias dk=docker
alias dkc=docker-compose
alias dkm=docker-machine
alias dkl='dk logs'
alias dkcl='dkc logs'

dkclr() {
  dk stop $(docker ps -a -q)
  dk rm $(docker ps -a -q)
}

dke() {
  dk exec -it "$1" "${@:1}"
}
