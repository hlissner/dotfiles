require_relative "../lib/package"

if is_mac?

  desc "Update/setup homebrew"
  task :homebrew => "homebrew:update"

  namespace :homebrew do
    task :setup do
      unless Package.installed?
        echo "Installing Homebrew..."
        Package.bootstrap

        Package.tap 'homebrew/dupes'
        Package.tap 'caskroom/cask'
      end

      Package.install 'brew-cask'

      # Essentials for all macs; specific brews are placed
      # in the node/*.rake files
      [ "coreutils",
        "wget",
        "curl",
        "tree",
        "git",
        "hub",
        "the_silver_searcher",
        "tmux",
        "gist",
        "lua",
        "readline",
        "openssl",
        "node"
      ].each { |pkg| Package.install pkg }

      [ "appcleaner",
        "vagrant",
        "virtualbox",
        "growlnotify",
        "iterm2",
        "java",
        "launchbar"
      ].each { |app| Package.cask_install app }

      echo "Homebrew is installed. Moving on."
    end

    task :update => "homebrew:setup" do
      echo "Updating homebrew..."
      Package.update
    end

    task :remove do
      Package.destroy if Package.installed?
    end
  end

elsif is_linux?

  desc "Update/setup aptitude"
  task :aptitude => "aptitude:update"

  namespace :aptitude do
    task :setup do
      echo "Updating packages..."
      Package.update

      [ "git",
        "tmux",
        "curl",
        "ruby2.0",
        "rake"
      ].each { |pkg| Package.install pkg }
    end

    task :update => 'aptitude:setup'
  end

end
