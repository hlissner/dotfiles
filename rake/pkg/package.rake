require_relative "../lib/package"

if is_mac?

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
      %w{
        coreutils
        wget
        curl
        tree
        git
        the_silver_searcher
        tmux
        gist
        lua
        luajit
        readline
        openssl
        node
      }.each { |pkg| Package.install pkg }

      %w{
        dropbox
        appcleaner
        vagrant
        virtualbox
        growlnotify
        iterm2
        java
        launchbar
      }.each { |app| Package.cask_install app }

      echo "Homebrew is installed. Moving on."
    end

    task :update => "homebrew:setup" do
      echo "Updating homebrew..."
      Package.update
    end

    desc "Remove homebrew cleanly"
    task :remove do
      Package.destroy if Package.installed?
    end
  end

elsif is_linux?

  namespace :aptitude do
    task :setup do
      # TODO Setup default linux package
    end

    task :update => 'aptitude:setup' do
      echo "Updating packages..."
      Package.update
    end
  end

end
