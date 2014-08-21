require_relative '../lib/homebrew'
require_relative '../lib/rbenv'

task :rbenv => 'rbenv:update'

namespace :rbenv do

    task :install do
        unless Rbenv.is_installed?
            echo "Installing rbenv"
            Rbenv.bootstrap
        end
    end

    task :remove do
        if Rbenv.is_installed?
            echo "rbenv isn't installed!"
        else
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
