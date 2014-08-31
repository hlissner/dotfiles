desc "Install/update pyenv & all pythons"
task :pyenv => 'pyenv:update'

namespace :pyenv do
  task :install do
    unless pyenv_installed?
      echo "Installing pyenv"
      if is_mac?
        pyenv_reqs.each { |pkg| Package.install pkg }
      elsif is_linux?
        sh_safe "curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash"
      end
    end
  end

  task :update => "pyenv:install" do
    pyenv_versions do |v|
      echo "Updating python #{v}"

      cmd = "pip"
      cmd = "sudo #{cmd}" if v == "system"

      sh_safe "PYENV_VERSION=#{v} #{cmd} freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs #{cmd} install -U"
    end
  end

  desc "Remove pyenv & installed pythons"
  task :remove do
    if pyenv_installed?
      echo "pyenv isn't installed!"
    else
      echo "Deleting pyenv"
      if is_mac?
        pyenv_reqs.each { |pkg| Package.remove pkg }
      elsif is_linux?
        sh_safe "rm -rf $PYENV_ROOT"
      end
    end
  end
end

####

def pyenv_installed?
  system("which pyenv")
end

def pyenv_versions
  `ls -1 $PYENV_ROOT/versions`.split("\n")
end

def pyenv_reqs
  %w{pyenv pyenv-pip-rehash pyenv-virtualenv}
end
