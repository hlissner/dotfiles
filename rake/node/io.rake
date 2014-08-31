desc "Provision main desktop"
task :io do
  %w{
    update
    pkg:osx
    pkg:zsh
    pkg:vim
    pkg:emacs
    pkg:rbenv
    pkg:pyenv
  }.each { |task| Rake::Task[task].invoke }

  if is_mac?
    %w{
      transmit
      transmission
      vlc
      flux
      skype
      adium
      codekit
      sequel-pro
      scrivener
      omnigraffle
      love
    }.each { |app| Package.cask_install app }
  end
end
