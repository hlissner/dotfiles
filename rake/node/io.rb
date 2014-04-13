require_relative '../lib/homebrew'

%w{
    osx
    homebrew
    zsh
    vim
    rbenv:v1_9
    rbenv:v2_0
    rbenv:update
    pyenv
}.each { |task| Rake::Task[task].invoke }

Homebrew.tap 'homebrew/python'
Homebrew.install 'pygame'

%w{
    evernote
    transmit
    transmission
    vlc
    flux
    skype
    adium
    codekit
    mongohub
    sequel-pro
    scrivener
    omnigraffle
    mindnode-pro
    love
    unity3d
}.each { |app| Homebrew.install_cask app }
