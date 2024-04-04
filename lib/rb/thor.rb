# lib/rb/thor.rb

require 'thor'
ENV['THOR_SILENCE_DEPRECATION'] = '1'

## Monkey patches
class CLI < Thor
  # HACK Hide noisy and redundant 'x help y' commands in documentation. We
  #   already remind users that -h/--help exist!
  def self.printable_commands(all=true, subcommand=false)
    super(all, subcommand).reject! { |l| l[0]&.split[-2] == 'help' }
  end

  def self.group(title, &)
    # TODO
    class_eval(&)
  end
end

# HACK Thor displays a --no-X variant of every boolean flag, with no way to
#   suppress this for flags where they don't make sense. This does three things
#   to remedy this:
#
# 1. Display the positive variant (--verbose) if the options default value is
#    false, and the negative variant (--no-verbose) if it's true.
# 2. If default is omitted/null, then show both variants, but...
# 3. Merge the two variants into one (i.e. '--verbose, --no-verbose' ->
#    '--[no-]verbose').
class Thor::Option
  def usage(padding=0)
    sample = switch_name
    sample = "#{switch_name}=#{banner}".dup if banner && !banner.to_s.empty?
    if boolean? and !(name == 'force' || name.start_with?('no-'))
      sample = dasherize((default ? 'no-' : default == nil ? '[no-]' : '') + human_name)
    end
    if aliases.empty?
      (" " * padding) << sample
    else
      "#{aliases.join(', ')}, #{sample}"
    end
  end
end
