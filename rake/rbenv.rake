
require_relative 'lib/homebrew'

task :rbenv do

end

namespace :rbenv do

    BREWS = %w{rbenv ruby-build rbenv-bundler rbenv-vars rbenv-gem-rehash}

    task :install do
        BREWS.each { |pkg| Homebrew.install pkg }
    end

    if Dir.exists?(File.expand_path("~/.rbenv"))
        task :remove do
            BREWS.each { |pkg| Homebrew.remove pkg }
            sh "rm -rf ~/.rbenv"
        end

        task :update => :install do

        end
    end

end
