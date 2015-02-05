def node_installed?
  File.exists?(is_mac? ? "/usr/local/bin/node" : "/usr/bin/nodejs")
end

desc "Ensure nodejs & its prerequisites are installed"
task :nodejs => "pkg:nodejs:update"

namespace :nodejs do
  desc "Install node.js completely"
  task :install do
    unless node_installed?
      echo "Installing node"
      if is_linux?
        sh_safe "curl -sL https://deb.nodesource.com/setup | sudo bash -"
        Package.update
      end

      Package.install is_mac? ? "node" : "nodejs"
      Package.install "npm" if is_linux?
    end
  end

  if node_installed?
    task :update => :install do
      echo "Updating node"
      if is_mac?
        Package.update "node"
      elsif is_linux?
        sh_safe "npm cache clean -f"
        sh_safe "npm update npm -g"
      end
    end

    task :remove do
      echo "Uninstalling node"
      sh_safe "npm uninstall npm -g"
      Package.remove is_mac? ? "node" : "nodejs"
    end
  end
end
