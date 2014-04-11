require_relative 'lib/homebrew'

%w{
    osx
    homebrew
    zsh
    vim
    gamedev:sfml
    gamedev:love2D
    gamedev:unity
    rbenv
    pyenv
}.each { |task| Rake::Task[task].invoke }

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
}.each { |app| Homebrew.install_cask app }
