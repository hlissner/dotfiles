
require_relative 'lib/git'

desc "Ensure zsh and oh-my-zsh is installed and set"
task :zsh => 'zsh:update'

namespace :zsh do

    task :install do
        unless Dir.exists?(File.expand_path("~/.oh-my-zsh"))
            echo "Installing oh-my-zsh"
            github 'robbyrussell/oh-my-zsh', '~/.oh-my-zsh'
            sh '~/.oh-my-zsh/install.sh'
        end

        unless `printenv SHELL | grep "/bin/zsh"`
            echo "Setting shell to zsh"
            sh "chsh -s /bin/zsh"
            sh "exec /bin/zsh -l"
        end
    end

    task :update => :install do
        echo "Updating oh-my-zsh"
        sh 'cd ~/.oh-my-zsh && git pull'
    end

end
