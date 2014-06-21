
require_relative "lib/output"
require_relative "lib/homebrew"

desc "Ensure vim/macvim is installed and up to date"
task :vim => "vim:update"

namespace :vim do

    task :install do
        %w{lua luajit}.each { |pkg| Homebrew.install pkg }
        %w{vim macvim}.each { |pkg| Homebrew.install(pkg, '--with-lua --with-luajit') }

        unless Dir.exists? (File.expand_path("~/.vim"))
            github('hlissner/vim', '~/.vim')
            github('Shougo/neobundle.vim', '~/.vim/bundle/neobundle.vim')
        end
    end

    task :update => 'vim:install' do
        path = File.expand_path("~/.vim")
        echo "Updating vim"
        sh "cd #{path} && git pull"
    end

    desc "Remove vim"
    task :remove do 
        echo "Uninstalling vim"
        %w{vim macvim}.each { |pkg| Homebrew.remove pkg }
    end

end
