desc "Ensure bash is setup & up-to-date"
task :bash => 'bash:update'

namespace :bash do
  task :install do
    echo "Attempting to install bash + completion"
    Package.install "bash"
    Package.install "bash-completion"

    if is_mac?
      # Write the new bash into shells if it isn't already there
      bash_bin = "/usr/local/bin/bash"
      if `cat /etc/shells | grep "^#{bash_bin}$"`
        echo "Writing '#{bash_bin}' to /etc/shells", 2
        sh_safe "echo '#{bash_bin}' | sudo tee -a /etc/shells"
      end

      sh_safe "chsh -s #{bash_bin}"
    end
  end

  task :update => "bash:install"

  task :remove do
    if is_mac?
      Package.remove "bash"
      Package.remove "bash-completion"
    end
  end
end
