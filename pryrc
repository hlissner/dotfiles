# Pry config

Pry.config.theme = 'monokai'

# Show ruby version/patch level in prompt
prompt = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
Pry.config.prompt = [
  proc { |obj, nest_level, _| "#{prompt} (#{obj}):#{nest_level} > " },
  proc { |obj, nest_level, _| "#{prompt} (#{obj}):#{nest_level} * " }
]

# https://github.com/michaeldv/awesome_print/
# $ gem install awesome_print
require 'awesome_print'
AwesomePrint.defaults = { indent: -2 }
AwesomePrint.pry!

## Benchmarking
# Inspired by <http://stackoverflow.com/questions/123494/whats-your-favourite-irb-trick/123834#123834>.
def time(repetitions = 100, &block)
  require 'benchmark'
  Benchmark.bm { |b| b.report { repetitions.times(&block) } }
end
