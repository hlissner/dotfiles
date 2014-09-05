# Homebrew package adapter
module Package
  module_function

  @@brew_bin = "/usr/local/bin/brew"

  def bootstrap
    unless self.installed?
      sh_safe 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
    end
  end

  def install(package)
    self.run("install", package) unless self.installed?(package)
  end

  def installed?(package = nil)
    return File.exists?(@@brew_bin) if !package

    self.run("list | grep -w '#{package}' >& /dev/null")
  end

  def remove(package)
    self.run("remove", package)
  end

  def update(*args)
    if args.length > 0
      self.run("upgrade #{args.join(' ')}")
    else
      self.run("update")
      self.run("upgrade")
    end
  end

  def tap(repo)
    self.run("tap", repo) unless self.tapped?(repo)
  end

  def untap(repo)
    self.run("untap #{repo}")
  end

  def tapped?(repo)
    self.run("tap | grep -w '#{repo}' >& /dev/null")
  end

  # Homebrew-specific functions
  def cask_install(cask)
    self.run("cask", "install", cask) unless self.cask_installed?(cask)
  end

  def cask_remove(cask)
    self.run("cask", "uninstall", cask) unless self.cask_installed?(cask)
  end

  def cask_installed?(cask)
    self.run("cask list | grep -w '#{cask}' >& /dev/null")
  end

  def run(*args)
    raise "Homebrew isn't installed!" unless self.installed?

    `#{@@brew_bin} #{args.join(' ')}`
  end
end
