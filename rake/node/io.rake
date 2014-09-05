desc "My main computer"
task :io do
  [ "update",
    "pkg:osx",
    "pkg:zsh",
    "pkg:vim",
    "pkg:emacs",
    "pkg:rbenv",
    "pkg:pyenv",
    "pkg:love"
  ].each { |task| Rake::Task[task].invoke }

  # Install my the mac-apps I commonly use
  if is_mac?
    [ "transmit",
      "transmission",
      "vlc",
      "flux",
      "skype",
      "adium",
      "codekit",
      "mindnode-pro",
      "sequel-pro",
      "scrivener",
      "omnigraffle",

      # Quicklook plugins
      "qlcolorcode",
      "qlstephen",
      "qlmarkdown",
      "quicklook-json",
      "qlprettypatch",
      "quicklook-csv",
      "betterzipql",
      "webp-quicklook",
      "suspicious-package"
    ].each { |app| Package.cask_install app }
  end

  if system("rbenv versions | grep 2.1.2 >/dev/null")
    sh_safe "rbenv install 2.1.2"
    sh_safe "rbenv global 2.1.2"

    sh_safe "~/.rbenv/shims/gem install bundler rspec cucumber jekyll"
  end

  if system("pyenv versions | grep 3.4.1 >/dev/null")
    sh_safe "pyenv install 3.4.1"
    sh_safe "pyenv global 3.4.1"

    sh_safe "~/.pyenv/shims/pip install nose cython"
  end
end
