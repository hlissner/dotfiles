include Rake::DSL

module Homebrew
    BIN = "/usr/local/bin/brew"

    def self.bootstrap
        unless self.is_installed?
            sh 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
            sh 'exec $SHELL -l'
        end
    end

    def self.destroy
        if self.is_installed?
            sh 'rm -rf /usr/local/Cellar /usr/local/.git ~/Library/Caches/Homebrew'
            sh 'brew prune'

            ['Library/Homebrew', 'Library/Aliases', 'Library/Formula', 'Library/Contributions'].each do |dir|
                sh "rm -r #{dir}"
            end
        end
    end

    def self.install(keg, options=nil)
        sh "#{BIN} install #{keg} #{options}" unless self.is_keg_installed?(keg)
    end

    def self.install_cask(cask, options=nil)
        sh "#{BIN} cask install #{cask} #{options}" unless self.is_cask_installed?(cask)
    end

    def self.tap(tap)
        sh "#{BIN} tap #{tap}" unless self.is_tapped? tap
    end

    def self.remove(keg)
        sh "#{BIN} remove #{keg}"
    end

    def self.has_keg?(keg)
        `#{BIN} search #{keg}`
    end

    def self.is_keg_installed?(keg)
        `#{BIN} list | grep -w '#{keg}'`
    end

    def self.is_cask_installed?(cask)
        `#{BIN} cask list | grep -w '#{cask}'`
    end

    def self.is_tapped?(tap)
        `#{BIN} tap | grep -w '#{tap}'`
    end

    def self.is_installed?
        File.exists?("/usr/local/bin/brew")
    end

    def self.prefix(keg)
        `#{BIN} --prefix #{keg}`.strip
    end

    def self.update(*args)
        if args.length > 0
            sh "#{BIN} upgrade #{args.join(' ')}"
        else
            sh "#{BIN} update && #{BIN} upgrade"
        end
    end
end
