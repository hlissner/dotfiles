#!/usr/bin/env zsh

set -e

indent() { sed 's/^/  /'; }
up-to-date() {
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    [[ "$LOCAL" == "$REMOTE" ]]
}

(( $+commands[brew] )) && {
    echo "Updating homebrew"
    { brew update; brew upgrade --all; brew cleanup } | indent
}

[[ -f "$HOME/.emacs.d/Makefile" ]] && {
    echo -n "Updating emacs"
    cd "$HOME/.emacs.d" && make update | indent
}

local env=(rb py)
for i in $env
do
    [[ -d "$HOME/.${i}env" ]] && {
        echo "Updating ${i}env"
        {
            git pull > /dev/null

            {
                for plugin in "$HOME"/.${i}env/plugins/*
                do
                    cd "$plugin"
                    echo "+ `basename ${plugin}`"
                    git pull > /dev/null
                done
            } 2&>1 | indent
        } 2&>1 | indent
    }
done

[[ -d ~/.zsh/zgen ]] && {
    echo "Updating zgen"
    {
        source "$HOME/.zsh/zgen/zgen.zsh"
        zgen selfupdate
        zgen update
    } 2&>1 | indent
}

