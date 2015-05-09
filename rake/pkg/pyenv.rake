PYENV_ROOT = File.expand_path("~/.pyenv")

def pyenv_installed?
  Dir.exists?(PYENV_ROOT)
end

def pyenv_versions
  `ls -1 #{PYENV_ROOT}/versions`.split("\n") if Dir.exists? "#{PYENV_ROOT}/versions"
end

def pyenv_plugins
  Dir.glob("#{PYENV_ROOT}/plugins/*")
end

def pyenv_version_installed?(version)
  versions = pyenv_versions
  versions.include?(version) if versions
end

###

desc "Install/update pyenv & all pythons"
task :pyenv => 'pyenv:update'

namespace :pyenv do
  task :install do
    unless pyenv_installed?
      echo "Installing pyenv"
      github "yyuu/pyenv", PYENV_ROOT

      [ "yyuu/pyenv-doctor",
        "yyuu/pyenv-installer",
        "yyuu/pyenv-pip-rehash",
        "yyuu/pyenv-update",
        "yyuu/pyenv-virtualenv",
        "yyuu/pyenv-which-ext"
      ].each do |pkg|
        echo "Installing #{pkg}", 2
        github pkg, "#{PYENV_ROOT}/plugins/#{pkg.split("/")[1]}"
      end

      echo "Initializing pyenv", 2
      sh_safe "eval \"$(#{PYENV_ROOT}/bin/pyenv init -)\""
      sh_safe "eval \"$(#{PYENV_ROOT}/bin/pyenv virtualenv-init -)\""
    end

    ['3.4.1', '2.7.8'].each do |version|
        unless pyenv_version_installed? version
            # Install global python + packages
            echo "Setting up default python (#{version})", 2
            sh_safe "pyenv install #{version}"
            sh_safe "pyenv global #{version}"
            sh_safe "PYENV_VERSION=#{version} #{PYENV_ROOT}/shims/pip install cython flake8"
            sh_safe "PYENV_VERSION=#{version} #{PYENV_ROOT}/shims/pip install nose virtualenv pyyaml ipython"
        end
    end
  end

  task :update => "pyenv:install" do
    echo "Updating pyenv & plugins"
    sh_safe "cd #{PYENV_ROOT} && git pull"
    pyenv_plugins.each do |dir|
      echo "Updating #{File.basename(dir)}", 2
      sh_safe "cd #{dir} && git pull"
    end

    pyenv_versions.each do |version|
      echo "Updating python #{version}", 2

      cmd = "#{PYENV_ROOT}/shims/pip"
      cmd = "sudo #{version}" if version == "system"

      sh_safe "PYENV_VERSION=#{version} #{cmd} freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs #{cmd} install -U"
    end
  end

  if pyenv_installed?
    task :remove do
      echo "Deleting pyenv"
      sh_safe "rm -rf #{PYENV_ROOT}"
    end
  end
end
