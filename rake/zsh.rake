require_relative 'lib/sh'
require_relative 'lib/git'

desc "Ensure zsh and oh-my-zsh is installed and set"
task :zsh => 'zsh:update'

namespace :zsh do

    task :install do
        unless Dir.exists?(File.expand_path("~/.oh-my-zsh"))
            echo "Installing oh-my-zsh"
            github 'robbyrussell/oh-my-zsh', '~/.oh-my-zsh'
        end
        sh_safe '~/.dotfiles/install.sh'

        unless `printenv SHELL | grep "/bin/zsh"`
            echo "Setting shell to zsh"
            sh_safe "chsh -s /bin/zsh"
            sh_safe "exec /bin/zsh -l"
        end
    end

    task :update => "zsh:install" do
        echo "Updating oh-my-zsh"
        sh_safe 'cd ~/.oh-my-zsh && git pull'
    end
    
    task :remove do
        sh_safe 'rm -rf ~/.oh-my-zsh' if Dir.exists?(File.expand_path("~/.oh-my-zsh"))
    end

end
