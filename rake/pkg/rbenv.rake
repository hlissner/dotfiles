desc "Install/update rbenv & all rubies"
task :rbenv => 'rbenv:update'

namespace :rbenv do
  task :install do
    unless rbenv_installed?
      echo "Installing rbenv"
      if is_mac?
        rbenv_reqs.each { |pkg| Package.install pkg }
      elsif is_linux?
        sh_safe "curl https://raw.githubusercontent.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash"
      end
    end
  end

  task :update => "rbenv:install" do
    rbenv_versions do |v|
      echo "Updating ruby #{v}"

      cmd = "gem"
      cmd = "sudo #{cmd}" if v == "system"

      sh_safe "RBENV_VERSION=#{version} #{cmd} #{GEM_BIN} update"
      sh_safe "RBENV_VERSION=#{version} #{cmd} #{GEM_BIN} clean"
    end
  end

  desc "Remove rbenv & installed rubies"
  task :remove do
    if rbenv_installed?
      echo "rbenv isn't installed!"
    else
      echo "Deleting rbenv"
      if is_mac?
        rbenv_reqs.each { |pkg| Package.remove pkg }
      elsif is_linux?
        sh_safe "rm -rf $RBENV_ROOT"
      end
    end
  end
end

####

def rbenv_installed?
  system("which rbenv")
end

def rbenv_versions
  `ls -1 $RBENV_ROOT/versions`.split("\n")
end

def rbenv_reqs
  %w{rbenv ruby-build rbenv-vars rbenv-gem-rehash}
end
