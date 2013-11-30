#!/bin/sh

source ~/.dotfiles/zsh/functions

BASEDIR=$(dirname "$0")

if ! is_mac; then
    echo_r "==> Aborting. This isn't a mac!"
    exit 1
fi

keep_alive
ln -sf ~/.dotfiles/zsh ~/.zsh
ln -sf ~/.dotfiles/zshrc ~/.zshrc
ln -sf ~/.dotfiles/zshenv ~/.zshenv

if ! command_exists brew; then
    echo_g "==> Installing homebrew"
    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"

    echo_g "==> Accept xcode agreement"
    sudo xcodebuild -license

    echo_g "==> Done! Please run this again (don't forget to do brew doctor first)"
else
    echo_g "==> Installing basic brews"
    if ! brew tap | grep dupes >/dev/null; then
        brew tap homebrew/dupes
    fi

    brew install wget curl git
    brew install the_silver_searcher
    brew install lua --with-completion

    if ! brew list | grep brew-cask >/dev/null; then
        echo_g "==> Installing brew cask"
        brew tap phinze/homebrew-cask
        brew install brew-cask
    else
        echo_g "==> Cask already installed!"
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            "--basic")
                echo_g "==> Installing basic bundle"

                # Install the apps I find essential for every mac I'm on 
                # (that I don't get through the app store)
                brew cask install appcleaner
                brew cask install google-chrome
                brew cask install launchbar
                brew cask install dropbox
                brew cask install iterm2
                brew cask install sequel-pro
                brew cask install transmission
                brew cask install transmit
                ;;
            "--dev")
                echo_g "==> Installing dev bundle"

                brew cask install codekit
                brew cask install vagrant
                ;;
            "--home") 
                echo_g "==> Installing home bundle"

                brew cask install adium
                brew cask install reggy
                brew cask install net-news-wire
                brew cask install soulver
                brew cask install scrivener
                brew cask install skype
                brew cask install vlc
                ;;
        esac
        shift
    done

    echo_g "==> Done!"
fi
