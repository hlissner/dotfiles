require_relative "sh"
require_relative "os"

include Rake::DSL

if is_mac?
  require_relative "package_adapters/homebrew.rb"
elsif is_linux?
  require_relative "package_adapters/aptitude.rb"
  # TODO Implement centos yum support
else
  raise "Could not detect OS"
end
