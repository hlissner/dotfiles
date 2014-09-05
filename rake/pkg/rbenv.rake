RBENV_ROOT = File.expand_path("~/.rbenv")

def rbenv_installed?
  Dir.exists?(RBENV_ROOT)
end

def rbenv_versions
  `ls -1 #{RBENV_ROOT}/versions`.split("\n") if Dir.exists? "#{RBENV_ROOT}/versions"
end

def rbenv_plugins
  Dir.glob("#{RBENV_ROOT}/plugins/*")
end

def rbenv_set_default_gems(gems)
  return if !gems.is_a?(Array) or gems.length == 0
  File.write("#{RBENV_ROOT}/default-gems", gems.join("\n"))
end

###

desc "Install/update rbenv & all rubies"
task :rbenv => 'rbenv:update'

namespace :rbenv do
  task :install do
    unless rbenv_installed?
      echo "Installing rbenv"
      github "sstephenson/rbenv", RBENV_ROOT

      mkdir_p "#{RBENV_ROOT}/plugins"
      [ "sstephenson/rbenv-vars",
        "sstephenson/ruby-build",
        "sstephenson/rbenv-default-gems",
        "sstephenson/rbenv-gem-rehash",
        "fesplugas/rbenv-installer",
        "fesplugas/rbenv-bootstrap",
        "rkh/rbenv-update",
        "rkh/rbenv-whatis",
        "rkh/rbenv-use"
      ].each do |pkg|
        echo "Installing #{pkg}", 2
        github pkg, "#{RBENV_ROOT}/plugins/#{pkg.split("/")[1]}"
      end

      echo "Initializing rbenv", 2
      sh_safe "eval \"$(#{RBENV_ROOT}/bin/rbenv init -)\""

      # Set default gems
      rbenv_set_default_gems(:bundler, :rspec, :pry, :factory_girl)

      # Install global ruby + gems
      ruby_version = "2.1.2"
      echo "Setting up default ruby (#{ruby_version})", 2
      sh_safe "rbenv install #{ruby_version}"
      sh_safe "rbenv global #{ruby_version}"
      sh_safe "RBENV_VERSION=#{ruby_version} #{RBENV_ROOT}/shims/gem install -f jekyll sass mercenary"
    end
  end

  task :update => "rbenv:install" do
    echo "Updating rbenv & plugins"
    sh_safe "rbenv update"

    rbenv_versions.each do |version|
      echo "Updating ruby #{version}"

      cmd = "#{RBENV_ROOT}/shims/gem"
      cmd = "sudo #{cmd}" if version == "system"

      sh_safe "RBENV_VERSION=#{version} #{cmd} update --system -f"
      sh_safe "RBENV_VERSION=#{version} #{cmd} update -f"
      sh_safe "RBENV_VERSION=#{version} #{cmd} clean"
    end
  end

  if rbenv_installed?
    task :remove do
      echo "Deleting rbenv"
      sh_safe "rm -rf #{RBENV_ROOT}"
    end
  end
end
