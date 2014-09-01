desc "Install/update rbenv & all rubies"
task :rbenv => 'rbenv:update'

RBENV_ROOT = File.expand_path("~/.rbenv")

namespace :rbenv do
  task :install do
    unless rbenv_installed?
      echo "Installing rbenv"
      sh_safe "curl https://raw.githubusercontent.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash"

      github "sstephenson/rbenv", RBENV_ROOT
      mkdir_p "#{rbenv_root}/plugins"
      [ "sstephenson/rbenv-vars",
        "sstephenson/ruby-build",
        "sstephenson/rbenv-default-gems",
        "sstephenson/rbenv-gem-rehash",
        "fesplugas/rbenv-installer",
        "fesplugas/rbenv-bootstrap",
        "rkh/rbenv-update",
        "rkh/rbenv-whatis",
        "rkh/rbenv-use"
      ].each { |pkg| github pkg, "#{RBENV_ROOT}/plugins/" }
    end
  end

  task :update => "rbenv:install" do
    echo "Updating rbenv & plugins"
    sh_safe "cd #{RBENV_ROOT} && git pull"
    rbenv_plugins do |dir|
      sh_safe "cd #{dir} && git pull"
    end

    rbenv_versions do |version|
      echo "Updating ruby #{version}"

      cmd = "gem"
      cmd = "sudo #{cmd}" if version == "system"

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
      sh_safe "rm -rf #{RBENV_ROOT}"
    end
  end
end

####

def rbenv_installed?
  system("which rbenv")
end

def rbenv_versions
  `ls -1 #{RBENV_ROOT}/versions`.split("\n") if Dir.exists? "#{RBENV_ROOT}/versions"
end

def rbenv_plugins
  Dir.glob("#{RBENV_ROOT}/plugins/*")
end
