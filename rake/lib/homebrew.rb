require_relative 'sh'

include Rake::DSL

module Homebrew
  BIN = "/usr/local/bin/brew"

  def self.bootstrap
    unless self.is_installed?
      sh_safe 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
      echo "Homebrew is installed! Restart the shell then rake."
      exit
    end
  end

  def self.destroy
    if self.is_installed?
      sh_safe 'rm -rf /usr/local/Cellar /usr/local/.git ~/Library/Caches/Homebrew'
      sh_safe 'brew prune'

      ['Library/Homebrew', 'Library/Aliases', 'Library/Formula', 'Library/Contributions'].each do |dir|
        sh_safe "rm -r #{dir}"
      end
    end
  end

  def self.install(keg, options=nil)
    sh_safe "#{BIN} install #{keg} #{options}" unless self.is_keg_installed?(keg)
  end

  def self.install_cask(cask, options=nil)
    sh_safe "#{BIN} cask install #{cask} #{options}" unless self.is_cask_installed?(cask)
  end

  def self.tap(tap)
    sh_safe "#{BIN} tap #{tap}" unless self.is_tapped? tap
  end

  def self.remove(keg)
    sh_safe "#{BIN} remove #{keg}"
  end

  def self.remove_cask(keg)
    sh_safe "#{BIN} cask uninstall #{keg}"
  end

  def self.has_keg?(keg)
    system("#{BIN} search #{keg}")
  end

  def self.is_keg_installed?(keg)
    system("#{BIN} list | grep -w '#{keg}' >& /dev/null")
  end

  def self.is_cask_installed?(cask)
    system("#{BIN} cask list | grep -w '#{cask}' >& /dev/null")
  end

  def self.is_tapped?(tap)
    system("#{BIN} tap | grep -w '#{tap}' >& /dev/null")
  end

  def self.is_installed?
    File.exists?("/usr/local/bin/brew")
  end

  def self.prefix(keg)
    `#{BIN} --prefix #{keg}`.strip
  end

  def self.update(*args)
    if args.length > 0
      sh_safe "#{BIN} upgrade #{args.join(' ')}"
    else
      sh_safe "#{BIN} update && #{BIN} upgrade"
    end
  end
end
