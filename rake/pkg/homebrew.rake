require_relative "../lib/output"
require_relative "../lib/homebrew"
require_relative "../lib/sh"

desc 'Install/update homebrew'
task :homebrew => 'homebrew:update'

namespace :homebrew do

    task :install do
        unless Homebrew.is_installed?
            echo "Installing Homebrew..."
            Homebrew.bootstrap
        end

        Homebrew.tap 'homebrew/dupes'
        Homebrew.tap 'caskroom/cask'
        Homebrew.install 'brew-cask'

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
        }.each { |pkg| Homebrew.install pkg }

        %w{
            dropbox
            appcleaner
            vagrant
            virtualbox
            growlnotify
            iterm2
            java
            launchbar
        }.each { |app| Homebrew.install_cask app }

        echo "Homebrew is installed. Moving on."
    end

    desc "Update homebrew and upgrade brews"
    task :update => "homebrew:install" do
        echo "Updating homebrew..."
        Homebrew.update
    end

    desc "Remove homebrew cleanly"
    task :remove do
        Homebrew.destroy if Homebrew.is_installed?
    end

end
