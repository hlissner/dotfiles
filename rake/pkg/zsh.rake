desc "Ensure zsh & prezto are installed"
task :zsh => 'zsh:update'

ENV["PREZTO_PATH"] = File.expand_path("~/.zprezto")

namespace :zsh do
  task :install do
    echo "Attempting to install ZSH"
    Package.install "zsh"

    unless Dir.exists? ENV["PREZTO_PATH"]
      echo "Installing prezto", 2
      github 'hlissner/prezto', ENV["PREZTO_PATH"]
    end
    sh_safe '~/.dotfiles/install.sh'

    unless `printenv SHELL | grep "/zsh$"`
      echo "Setting shell to ZSH", 2
      zsh_bin = is_mac? ? "/usr/local/bin/zsh" : "/usr/bin/zsh"
      if !File.exists? zsh_bin
        error "ZSH isn't in #{File.dirname(zsh_bin)}"
        next
      end

      # Write the new zsh into shells if it isn't already there
      if `cat /etc/shells | grep "^#{zsh_bin}$"`
        echo "Writing '#{zsh_bin}' to /etc/shells", 3
        sh_safe "echo '#{zsh_bin}' | sudo tee -a /etc/shells"
      end

      sh_safe "chsh -s #{zsh_bin}"
    end

    echo "Comment out path_helper to fix PATH in emacs!" if is_mac?
  end

  task :update => "zsh:install" do
    echo "Updating zprezto"
    sh_safe 'cd ~/.zprezto && git pull'
  end

  task :remove do
    sh_safe 'rm -rf ~/.zprezto' if Dir.exists? ENV["PREZTO_PATH"]
  end
end
