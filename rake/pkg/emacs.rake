if is_mac?

  ENV['EMACS_D'] = File.expand_path("~/.emacs.d")

  desc "Ensure emacs is installed and up to date"
  task :emacs => "emacs:update"

  namespace :emacs do
    task :install do
      unless Dir.exists? ENV[:EMACS_D]
        github 'hlissner/emacs.d', '~/.emacs.d'
        Package.install "homebrew/dupes/tidy --HEAD"
        emacs_reqs.each { |pkg| Package.install pkg }

        sh_safe "/usr/local/bin/npm install jshint -g"
        sh_safe "/usr/local/bin/npm install jsonlint -g"
        sh_safe "cd ~/.emacs.d && cask"
      end
    end

    task :update do
      echo "Updating emacs.d & packages"
      sh_safe "cd ~/.emacs.d && git pull && cask update"

      # Update rsense config
      sh_safe "~/.rbenv/shims/ruby `brew --prefix rsense`/libexec/etc/config.rb > ~/.rsense"
    end

    task :remove do
      echo "Uninstalling emacs"
      Package.remove "emacs"
      Package.remove "homebrew/dupes/tidy"
      emacs_reqs.each { |pkg| Package.remove pkg }

      rm_rf "~/.emacs.d" if Dir.exists? ENV['EMACS_D']
    end
  end

  def emacs_reqs
    [
      "emacs --with-gnutls --cocoa --keep-ctags --srgb",
      "aspell --with-lang-en",
      "cask",
      "rsense"
    ]
  end

end
