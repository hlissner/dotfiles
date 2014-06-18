include Rake::DSL
require_relative 'homebrew'

module Rbenv

    BREWS = %w{rbenv ruby-build rbenv-bundler rbenv-vars rbenv-gem-rehash}

    def self.bootstrap
        unless self.is_installed?
            BREWS.each { |pkg| Homebrew.install pkg }
            sh_safe 'exec $SHELL -l'
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
        end
        sh_safe "RBENV_VERSION=#{version} gem install #{gems.join(' ')}"
    end

    def self.update(version)
        sh_safe "RBENV_VERSION=#{version} gem update"
        sh_safe "RBENV_VERSION=#{version} gem clean"
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

end
