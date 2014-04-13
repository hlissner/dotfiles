
require_relative "lib/output"
require_relative "lib/homebrew"

desc "Ensure vim/macvim is installed and up to date"
task :vim

namespace :vim do

    task :install do
        %w{lua luajit}.each { |pkg| Homebrew.install pkg }
        %w{vim macvim}.each { |pkg| Homebrew.install(pkg, '--with-lua --with-luajit') }

        github('hlissner/vim', '~/.vim') unless Dir.exists?(File.expand_path("~/.vim"))
    end

    desc "Remove vim"
    task :remove do 
        echo "Uninstalling Homebrew"
        %w{vim macvim}.each { |pkg| Homebrew.remove pkg }
    end

end
