#!/usr/bin/env bash

set -o errexit,nounset

update() {
    [[ -d $1 ]] || return

    pushd "$1"
    local L=$(git rev-parse @)
    local R=$(git rev-parse @{u})
    if [[ $L != $R ]]
    then
        echo "Updating $(basename $(pwd))"
        shift
        ${@:-git pull}
    fi
    popd
}

# Update OS
case "$OSTYPE" in
    darwin*)
        brew update && brew upgrade && brew cleanup
        ;;
    linux*)
        if command -v pacman >/dev/null; then
            sudo pacman -Syu --noconfirm
        elif command -v apt-get >/dev/null; then
            sudo apt-get update && sudo apt-get upgrade -y
        fi
esac

# Update editors
update ~/.emacs.d "make update"
update ~/.vim     "make update"

# Others
update ~/.zgen
update ~/.cask
update ~/.{rb,py}env

