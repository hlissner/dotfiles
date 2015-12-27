#!/usr/bin/env bash

if ! command -v "brew" >/dev/null; then
    echo "Homebrew isn't installed. Installing it!"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

BREW=/usr/local/bin/brew
{
    install() { ${BREW} install $@; }
    tap()     { ${BREW} tap $@; }

    brew update; brew upgrade --all; brew cleanup;

    tap caskroom/cask
    tap neovim/neovim
    tap homebrew/php
    tap homebrew/python
    tap homebrew/science
    tap homebrew/text
    tap nviennot/tmate

    install wget git curl hub watch tmux tree jq
    install imagemagick pandoc
    install the_silver_searcher
    install zsh --without-etcdir
    install fasd fzf

    # Emacs ###############################################
    install emacs --with-cocoa --with-imagemagick --HEAD
    install neovim macvim

    # Programming
    install go rust node # nim
    # Code tools
    install editorconfig racer boris plantuml

    cask java dropbox love virtualbox vagrant
    cask basictex
    cask appcleaner
    cask skype

} 2>&1 | sed 's/^/  /'

