# Aptitude (ubuntu/debian) package adapter
module Package
  module_function

  def bootstrap; end

  def install(package)
    self.run("install", "-y", package)
  end

  def installed?; end

  def remove(package); end

  def update(*args); end

  def tap(repo)
    sh_safe "sudo add-apt-repository #{repo}"
  end

  def untap(repo); end

  def tapped?(repo); end

  # TODO Finish aptitude adapter

  def run(*args)
    system("sudo apt-get #{args.join(' ')}")
  end
end
