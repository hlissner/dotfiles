require_relative '../lib/homebrew'

%w{
    osx
    homebrew
    zsh
    vim
    rbenv:v1_9
    rbenv:v2_0
    rbenv:update
}.each { |task| Rake::Task[task].invoke }

%w{
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
    love
}.each { |app| Homebrew.install_cask app }
