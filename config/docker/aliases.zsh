alias d=docker
alias dc=docker-compose
alias dm=docker-machine
alias dl='dk logs'
alias dcl='dkc logs'

dclr() {
  d stop $(docker ps -a -q)
  d rm $(docker ps -a -q)
}

de() {
  d exec -it "$1" "${@:1}"
}
