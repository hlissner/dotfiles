def is_mac?
  RUBY_PLATFORM =~ /darwin/
end

def is_linux?
  RUBY_PLATFORM =~ /linux/
end

# TODO Implement other linux distro tests
