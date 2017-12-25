alias docker='sudo docker'
alias docker-compose='sudo docker-compose'

alias dkc=docker-compose
alias dkm=docker-machine

dk() {
  case $(_os) in
    macos) if [[ -z $DOCKER_HOST ]]; then
             docker-machine start dev && eval $(docker-machine env)
           fi
           ;;
    arch)  systemctl -q is-active docker || sudo systemctl start docker ;;
  esac
  docker $@
}; compdef dk=docker
