if is_mac?

  ENV["EMACS_D"] = File.expand_path("~/.emacs.d")

  def emacs_reqs
    [
      "emacs --HEAD --use-git-head --with-gnutls --cocoa --keep-ctags --srgb",
      "aspell --with-lang-en",
      "cask",
      "rsense",
      "node"
    ]
  end

  def emacs_installed?
    Dir.exists?(ENV["EMACS_D"])
  end

  desc "Ensure emacs 24.4 is installed & up to date"
  task :emacs => "emacs:update"

  namespace :emacs do
    task :install do
      emacs_reqs.each { |pkg| Package.install pkg }
      unless emacs_installed?
        echo "Installing emacs dependencies"
        Package.install "homebrew/dupes/tidy --HEAD"

        echo "Setting up Emacs"
        github 'hlissner/emacs.d', '~/.emacs.d'

        sh_safe "/usr/local/bin/npm install jshint -g"
        sh_safe "/usr/local/bin/npm install jsonlint -g"
        sh_safe "cd '#{ENV["EMACS_D"]}' && cask"
      end
    end

    task :update => "emacs:install" do
      echo "Updating emacs.d & packages"
      sh_safe "cd '#{ENV["EMACS_D"]}' && git pull && cask update"

      # Update rsense config
      sh_safe "~/.rbenv/shims/ruby `brew --prefix rsense`/libexec/etc/config.rb > ~/.rsense"
    end

    task :remove do
      echo "Uninstalling emacs"
      Package.remove "emacs"
      Package.remove "homebrew/dupes/tidy"
      emacs_reqs.each { |pkg| Package.remove pkg }

      rm_rf ENV["EMACS_D"] if Dir.exists? ENV["EMACS_D"]
    end
  end

end
