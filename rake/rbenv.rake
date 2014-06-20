
require_relative 'lib/homebrew'
require_relative 'lib/rbenv'

task :rbenv => 'rbenv:update'

namespace :rbenv do

    GLOBAL_GEMS = %w{bundler pry rspec rake bluecloth}

    task :install do
        unless Rbenv.is_installed?
            echo "Installing rbenv"
            Rbenv.bootstrap
        end
    end

    task :v2_0 => "rbenv:install" do
        v = "2.0.0-p451"
        unless Rbenv.is_version_installed?(v)
            echo "Building ruby #{v}"
            Rbenv.install v, GLOBAL_GEMS
        end
    end

    task :v1_9 => "rbenv:install" do
        v = "1.9.3-p545"
        unless Rbenv.is_version_installed?(v)
            echo "Building ruby #{v}"
            Rbenv.install v, GLOBAL_GEMS
        end
    end

    if Rbenv.is_installed?
        task :remove do
            echo "Deleting rbenv"
            Rbenv.destroy
        end
    end

    task :update => "rbenv:install" do
        Rbenv.installed_versions.each do |v| 
            echo "Updating ruby #{v}"
            Rbenv.update v
        end
    end

end
