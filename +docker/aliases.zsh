case $OSTYPE in
    darwin*)
        alias dkm='docker-machine'
        alias dki='eval $(docker-machine env)'
        ;;
    linux*)
        alias docker='sudo docker'
        ;;
esac

alias dk='docker'
alias dkc='docker-compose'
