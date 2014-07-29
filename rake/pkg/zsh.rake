require_relative '../lib/sh'
require_relative '../lib/git'

desc "Ensure zsh and oh-my-zsh is installed and set"
task :zsh => 'zsh:update'

namespace :zsh do

    task :install do
        unless Dir.exists?(File.expand_path("~/.zprezto"))
            echo "Installing prezto"
            github 'hlissner/prezto', '~/.zprezto'
        end
        sh_safe '~/.dotfiles/install.sh'

        unless `printenv SHELL | grep "/bin/zsh"`
            echo "Setting shell to zsh"
            sh_safe "chsh -s /bin/zsh"
            sh_safe "exec /bin/zsh -l"
        end
    end

    task :update => "zsh:install" do
        echo "Updating zprezto"
        sh_safe 'cd ~/.zprezto && git pull'
        # TODO: pull from parent repo
    end
    
    task :remove do
        sh_safe 'rm -rf ~/.zprezto' if Dir.exists?(File.expand_path("~/.zprezto"))
    end

end
