# Aptitude (ubuntu/debian) package adapter
module Package
  module_function

  def bootstrap; end

  def install(package)
    self.run("install", "-y", package)
  end

  # TODO Finish aptitude adapter

  def run(*args)
    system("sudo apt-get #{args.join(' ')}")
  end
end
