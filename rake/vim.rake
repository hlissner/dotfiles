
require_relative "lib/output"
require_relative "lib/homebrew"

desc "Ensure vim/macvim is installed and up to date"
task :vim => 'vim:update'

namespace :vim do

    task :install => 'homebrew' do
        %w{lua luajit}.each { |pkg| Homebrew.install pkg }
        %w{vim macvim}.each { |pkg| Homebrew.install(pkg, '--with-lua --with-luajit') }

        github 'hlissner/vim', '~/.vim'
    end

    task :update => :install do
        echo "Updating homebrew..."
        Homebrew.update
    end

    desc "Remove homebrew cleanly"
    task :remove do 
        echo "Uninstalling Homebrew"
        Homebrew.destroy
    end

end
