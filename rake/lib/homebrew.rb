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
        system("#{BIN} search #{keg}")
    end

    def self.is_keg_installed?(keg)
        system("#{BIN} list | grep -w '#{keg}'")
    end

    def self.is_cask_installed?(cask)
        system("#{BIN} cask list | grep -w '#{cask}'")
    end

    def self.is_tapped?(tap)
        system("#{BIN} tap | grep -w '#{tap}'")
    end

    def self.is_installed?
        File.exists?("usr/local/bin/brew")
    end
    
    def self.update()
        sh "#{BIN} update && #{BIN} upgrade"
    end
end
