include Rake::DSL
require_relative 'homebrew'

module Rbenv

    BREWS = %w{rbenv ruby-build rbenv-bundler rbenv-vars rbenv-gem-rehash}

    GEM_BIN = "/usr/local/opt/rbenv/shims/gem"

    def self.bootstrap
        unless self.is_installed?
            BREWS.each { |pkg| Homebrew.install pkg }
            echo "Rbenv is installed! Restart the shell then rake."
            exit
        end
    end

    def self.destroy
        if self.is_installed?
            BREWS.each { |pkg| Homebrew.remove pkg }
            # sh_safe "rm -rf #{Homebrew.prefix 'rbenv'}"
        end
    end

    def self.install(version, gems=[])
        unless self.is_version_installed?(version)
            sh_safe "rbenv install #{version}"
            sh_safe "RBENV_VERSION=#{version} #{GEM_BIN} install #{gems.join(' ')}"
        end
    end

    def self.update(version)
        cmd = self._sudo(version)
        sh_safe "RBENV_VERSION=#{version} #{cmd} #{GEM_BIN} update"
        sh_safe "RBENV_VERSION=#{version} #{cmd} #{GEM_BIN} clean"
    end

    def self.is_installed?
        Homebrew.is_keg_installed? "rbenv"
    end

    def self.is_version_installed?(version)
        system("rbenv versions | grep -w #{version} &>/dev/null")
    end

    def self.installed_versions
        `ls -1 #{Homebrew.prefix 'rbenv'}/versions`.split("\n")
    end

    def self._sudo(version)
        if version == 'system'
            return "sudo"
        else
            return ""
        end
    end

end
