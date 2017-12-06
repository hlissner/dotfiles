dk() {
  case $(.os) in
    macos) if [[ -z $DOCKER_HOST ]]; then
             docker-machine start dev && eval $(docker-machine env)
           fi
           ;;
    arch)  systemctl -q is-active docker || sudo systemctl start docker ;;
  esac
  sudo docker $@
}; compdef dk=docker

alias dkc=docker-compose
alias dkm=docker-machine
