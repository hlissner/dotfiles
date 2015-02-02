if is_mac?

  ENV["EMACS_D"] = File.expand_path("~/.emacs.d")

  def emacs_reqs
    [ "emacs --with-gnutls --cocoa",
      "ispell",
      "cask",
      "rsense",
      "markdown" ]
  end

  def node_reqs
    %w{jshint jsonlint js-beautify git://github.com/ramitos/jsctags.git}
  end

  def setup
    echo "Installing emacs dependencies"
    emacs_reqs.each { |pkg| Package.install pkg }
  end

  def setup_node
    echo "Installing node dependencies"
    sh_safe "/usr/local/bin/npm install -g #{node_reqs.join(' ')}"
  end

  def setup_emacs_d
    echo "Setting up emacs.d & updating cask"
    github 'hlissner/emacs.d', '~/.emacs.d'
    sh_safe "cd '#{ENV["EMACS_D"]}' && cask install"
  end

  def emacs_installed?
    Dir.exists?(ENV["EMACS_D"])
  end

  #
  desc "Ensure emacs 24.4 is installed & up to date"
  task :emacs => "emacs:update"

  namespace :emacs do
    desc "Install emacs completely"
    task :install => ["nodejs:install", :setup, :setup_node, :setup_emacs_d]

    desc "Setup required homebrew packages"
    task :setup do
      setup if !emacs_installed? || ENV["FORCE"]
    end

    desc "Setup required node & node plugins"
    task :setup_node do
      setup_node if !emacs_installed? || ENV["FORCE"]
    end

    desc "Setup emacs.d folder, plugins and cask"
    task :setup_emacs_d do
      setup_emacs_d if !emacs_installed? || ENV["FORCE"]
    end

    task :update => "emacs:install" do
      if emacs_installed? && Dir.exists?("#{ENV['EMACS_D']}/.git")
        echo "Updating emacs.d & packages"
        sh_safe "cd '#{ENV["EMACS_D"]}' && git pull && cask update"

        # Update node
        sh_safe "/usr/local/bin/npm update -g #{node_reqs.join(' ')}"

        # Update rsense config
        sh_safe "/usr/bin/env ruby `brew --prefix rsense`/libexec/etc/config.rb > ~/.rsense"
      end
    end

    task :remove do
      echo "Uninstalling emacs"
      Package.remove "emacs"
      Package.remove "homebrew/dupes/tidy"
      emacs_reqs.each { |pkg| Package.remove pkg.split.first }

      rm_rf ENV["EMACS_D"] if Dir.exists? ENV["EMACS_D"]
    end
  end

end
