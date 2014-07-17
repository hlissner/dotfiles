require_relative '../lib/homebrew'

desc "Provision main desktop"
task :io do
    %w{
        pkg:osx
        pkg:homebrew
        pkg:zsh
        pkg:vim
        pkg:emacs
        pkg:rbenv:v1_9
        pkg:rbenv:v2_0
        pkg:rbenv:update
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
end
