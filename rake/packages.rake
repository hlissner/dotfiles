require_relative "lib/git"
require_relative "lib/os"
require_relative "lib/output"
require_relative "lib/rake"
require_relative "lib/sh"

verbose(false)

namespace :pkg do
  desc 'Setup/update package manager & packages'
  if is_mac?
    task :update => 'homebrew:update'
  elsif is_linux?
    task :update => 'aptitude:update'
  else
    task :update do
      echo "Package manager not implemented for this OS"
    end
  end

  load_all("pkg/*.rake")
end

namespace :test do
  task :output do
    echo "Testing output"
    echo "Testing sub-header output", 2
    echo "Another sub-header", 3

    error "A big bad error!"
  end

  task :tasks do
    sh "echo 'This should pass'"
    sh_safe "fake-command_ This should fail" # without disrupting the task
  end
end
