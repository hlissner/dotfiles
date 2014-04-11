%w{
    osx
    homebrew
    zsh
    vim
    rbenv
    mongodb
}.each { |task| Rake::Task[task].invoke }
