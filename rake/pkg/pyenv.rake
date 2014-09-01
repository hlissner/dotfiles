desc "Install/update pyenv & all pythons"
task :pyenv => 'pyenv:update'

PYENV_ROOT = File.expand_path("~/.pyenv")

namespace :pyenv do
  task :install do
    unless pyenv_installed?
      echo "Installing pyenv"

      github "yyuu/pyenv", PYENV_ROOT
      mkdir_p "#{PYENV_ROOT}/plugins"
      [ "yyuu/pyenv-doctor",
        "yyuu/pyenv-installer",
        "yyuu/pyenv-pip-rehash",
        "yyuu/pyenv-update",
        "yyuu/pyenv-virtualenv",
        "yyuu/pyenv-which-ext"
      ].each { |pkg| github pkg, "#{PYENV_ROOT}/plugins/" }

      sh_safe "eval $(~/.pyenv/bin/pyenv init -)"
      sh_safe "eval $(~/.pyenv/bin/pyenv virtualenv-init -)"
    end
  end

  task :update => "pyenv:install" do
    echo "Updating pyenv & plugins"
    sh_safe "cd #{PYENV_ROOT} && git pull"
    pyenv_plugins do |dir|
      sh_safe "cd #{dir} && git pull"
    end

    pyenv_versions do |version|
      echo "Updating python #{version}"

      cmd = "pip"
      cmd = "sudo #{version}" if v == "system"

      sh_safe "PYENV_VERSION=#{version} #{cmd} freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs #{cmd} install -U"
    end
  end

  if pyenv_installed?
    desc "Remove pyenv & installed pythons"
    task :remove do
      echo "Deleting pyenv"
      sh_safe "rm -rf #{PYENV_ROOT}"
    end
  end
end

####

def pyenv_installed?
  system("which pyenv")
end

def pyenv_versions
  `ls -1 #{PYENV_ROOT}/versions`.split("\n") if Dir.exists? "#{PYENV_ROOT}/versions"
end

def pyenv_plugins
  Dir.glob("#{PYENV_ROOT}/plugins/*")
end
