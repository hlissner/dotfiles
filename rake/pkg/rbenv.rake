RBENV_ROOT = File.expand_path('~/.rbenv')

def rbenv_installed?
  Dir.exist?(RBENV_ROOT)
end

def rbenv_versions
  return [] unless Dir.exist? "#{RBENV_ROOT}/versions"
  `ls -1 #{RBENV_ROOT}/versions`.split("\n")
end

def rbenv_plugins
  Dir.glob("#{RBENV_ROOT}/plugins/*")
end

def rbenv_set_default_gems(*gems)
  default_gems_file = "#{RBENV_ROOT}/default-gems"
  File.write(default_gems_file, gems.join("\n"))
end

def rbenv_version_installed?(version)
  rbenv_versions.include?(version)
end

###

desc 'Install/update rbenv & all rubies'
task rbenv: 'rbenv:update'

namespace :rbenv do
  task :install do
    unless rbenv_installed?
      echo 'Installing rbenv'
      github 'sstephenson/rbenv', RBENV_ROOT

      mkdir_p "#{RBENV_ROOT}/plugins"
      ['sstephenson/rbenv-vars',
       'sstephenson/ruby-build',
       'sstephenson/rbenv-default-gems',
       'sstephenson/rbenv-gem-rehash',
       'fesplugas/rbenv-installer',
       'fesplugas/rbenv-bootstrap',
       'rkh/rbenv-update',
       'rkh/rbenv-whatis',
       'rkh/rbenv-use'
      ].each do |pkg|
        echo "Installing #{pkg}", 2
        github pkg, "#{RBENV_ROOT}/plugins/#{pkg.split('/')[1]}"
      end

      echo 'Initializing rbenv', 2
      sh_safe "eval \"$(#{RBENV_ROOT}/bin/rbenv init -)\""
    end

    # Set default gems
    rbenv_set_default_gems(
      'bundler',
      'rspec',
      'doing',
      'pry',
      'pry-doc',
      'pry-byebug',
      'pry-rescue',
      'pry-stack_explorer',
      'ripper-tags',
      'gem-ripper-tags'
    )

    # Install global ruby + gems
    ruby_version = '2.1.6'
    unless rbenv_version_installed? ruby_version
      echo "Setting up default ruby (#{ruby_version})", 2
      sh_safe "rbenv install #{ruby_version}"
      sh_safe "rbenv global #{ruby_version}"
      sh_safe "RBENV_VERSION=#{ruby_version} #{RBENV_ROOT}/shims/gem install -f jekyll sass mercenary colorize pry pry-doc pry-byebug rake"
    end
  end

  task update: 'rbenv:install' do
    echo 'Updating rbenv & plugins'
    sh_safe 'rbenv update'

    rbenv_versions.each do |version|
      echo "Updating ruby #{version}"

      cmd = "#{RBENV_ROOT}/shims/gem"
      cmd = "sudo #{cmd}" if version == 'system'

      sh_safe "RBENV_VERSION=#{version} #{cmd} update --system -f"
      sh_safe "RBENV_VERSION=#{version} #{cmd} update -f"
      sh_safe "RBENV_VERSION=#{version} #{cmd} clean"
    end

    sh_safe 'rbenv rehash'
  end

  if rbenv_installed?
    task :remove do
      echo 'Deleting rbenv'
      sh_safe "rm -rf #{RBENV_ROOT}"
    end
  end
end
