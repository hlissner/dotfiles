
require_relative "lib/output"
require_relative "lib/homebrew"

desc "Ensure homebrew is installed and up to date"
task :homebrew => 'homebrew:update'

namespace :homebrew do

    task :install do
        unless Homebrew.is_installed?
            echo "Installing Homebrew..."
            Homebrew.bootstrap
        end

        Homebrew.tap('homebrew/dupes')
        Homebrew.tap('phinze/cask')

        %w{
            coreutils
            wget
            curl
            tree
            git
            brew-cask
            the_silver_searcher
            tmux
            gist
            lua
            luajit
        }.each { |pkg| Homebrew.install pkg }

        %w{
            dropbox
            firefox
            appcleaner
            vagrant
            virtualbox
            growlnotify
            iterm2
            launchbar
            java
        }.each { |app| Homebrew.install_cask app }

        echo "Homebrew is installed. Moving on."
    end

    task :update => :install do
        echo "Updating homebrew..."
        Homebrew.update
    end

    desc "Remove homebrew cleanly"
    task :remove do
        Homebrew.destroy if Homebrew.is_installed?
    end

end

