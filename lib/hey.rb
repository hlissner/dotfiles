# lib/hey.rb
# Author:  Henrik Lissner
# Version: 0.0.1
#
##

require 'thor'
require 'json'
require 'shellwords'
require 'fileutils'
require 'open3'
require 'tmpdir'
ENV['THOR_SILENCE_DEPRECATION'] = '1'

def user_error message
  STDERR.puts "ERROR: #{message}".red
  exit 1
end

class File
  def self.locate(file, dir = Dir.pwd)
    loop do
      break if dir == "/"
      file = "#{dir}/#{file}"
      return dir if exists?(file)
      dir = expand_path("..", dir)
    end
  end
end

class String
  def black;          _wrap 30 end
  def red;            _wrap 31 end
  def green;          _wrap 32 end
  def brown;          _wrap 33 end
  def blue;           _wrap 34 end
  def magenta;        _wrap 35 end
  def cyan;           _wrap 36 end
  def gray;           _wrap 37 end

  def bold;           _wrap 1, 22 end
  def italic;         _wrap 3, 23 end
  def underline;      _wrap 4, 24 end
  def reverse_color;  _wrap 7, 27 end

  def color?; STDOUT.isatty end
  private def _wrap code, b=0
    color? ? "\e[#{code}m#{self}\e[#{b}m" : self
  end
end

class Flake
  ATTRS = [ :path, :host, :user, :theme ]
  attr_reader(*ATTRS)

  def initialize(uri, user: nil, host: nil, theme: ENV['THEME'], **options)
    uri = locate(uri || Dir.pwd)
    @explicit = !uri
    if uri ||= File.expand_path('..', File.dirname(__FILE__))
      if m = uri.match(/^(.+)#(.+)$/)
        path, host = m[1], m[2]
      else
        path = uri
        host ||= `hostname`.rstrip
        host = nil if host == "nixos"
        user ||= `whoami`.rstrip
        user = nil if user == "root"
      end
      @path = File.realpath(File.expand_path(path))
      @host = host
      @user = user
      @theme = theme
    end
  end

  def to_h
    ATTRS.map { |k| [k, instance_variable_get("@#{k}")] }.to_h
  end

  def to_json
    to_h.to_json
  end

  def valid!
    STDERR.puts "No flake at #{Dir.pwd}. Falling back to #{uri}".red if explicit?
    user_error "No flake path specified" unless path
    user_error "No flake hostname specified for #{path}" unless host
    user_error "Could not find a host config for #{host} in #{path}/hosts" unless File.directory? "#{path}/hosts/#{host}"
  end

  def uri
    "#{@path}##{@host}"
  end

  def explicit?
    @explicit
  end

  def dotfiles?(dir = path)
    tmpfile = "/tmp/heyerror"
    begin
      json = `__HEYARGS="{}" nix flake show --impure --no-warn-dirty --json #{dir} 2>#{tmpfile}`.rstrip
      unless $? == 0
        user_error <<~END
          Flake emitted an error and cannot be polled:

          #{File.read(tmpfile)}
        END
      end
      JSON.parse(json.rstrip).has_key?("_heyArgs")
    ensure
      File.delete(tmpfile)
    end
  end

  def locate(dir = Dir.pwd)
    loop do
      break if dir.nil? or dir == "/"
      file = "#{dir}/flake.nix"
      if File.exists?(file)
        return dir if dotfiles?(dir)
      end
      dir = File.locate("flake.nix", File.expand_path("..", dir))
    end
  end
end

class HeyCLI < Thor
  ## Monkey patches
  # HACK Hide noisy and redundant 'x help y' commands in documentation. We
  #   already remind users that -h/--help exist!
  def self.printable_commands(all = true, subcommand = false)
    list = super(all, subcommand)
    list.reject! {|l| l[0].split[-2] == 'help'}
  end

  def self.group title, &block
    # TODO
    class_eval(&block)
  end

  def self.load_subcommand(command, summary = "TODO", className: nil)
    self.class_eval do
      cmd = command.to_s.split.first
      load "hey#{cmd}"
      desc "#{command} COMMAND", summary
      subcommand cmd, className || Object.const_get("::#{command.to_s.split.first.capitalize}")
    end
  end

  # HACK Thor displays a --no-X variant of every boolean flag, with no way to
  #   suppress this for flags where they don't make sense. This does three
  #   things to remedy this:
  #
  # 1. Display the positive variant (--verbose) if the options default value is
  #    false, and the negative variant (--no-verbose) if it's true.
  # 2. If default is omitted/null, then show both variants, but...
  # 3. Merge the two variants into one (i.e. '--verbose, --no-verbose' ->
  #    '--[no-]verbose').
  class Thor::Option
    def usage padding = 0
      sample = switch_name
      sample = "#{switch_name}=#{banner}".dup if banner && !banner.to_s.empty?
      if boolean? and !(name == "force" || name.start_with?("no-"))
        sample = dasherize((default ? 'no-' : default == nil ? '[no-]' : '') + human_name)
      end
      if aliases.empty?
        (" " * padding) << sample
      else
        "#{aliases.join(', ')}, #{sample}"
      end
    end
  end

  no_commands do
    # HACK options' keys are strings, making them difficult to double-splat
    #   around. Since it is frozen just before a CLI command is executed, it's
    #   safe to mutate, but this could break in the future.
    def invoke_command(command, *args)
      @options = @options ? @options.transform_keys(&:to_sym) : {}
      @flake = Flake.new(@options[:flake], **@options)
      puts "* #{@flake.to_h}" if @options[:dryrun]
      super command, *args
    end

    ## Helpers
    def run(*args, sudo: false, noerror: false)
      args.flatten!
      args.compact!
      args.unshift('sudo') if sudo
      ENV['__HEYARGS'] = @flake.to_json
      if options[:backtrace]
        args.append "--show-trace"
      end
      if options[:dryrun]
        print "$ #{args.shelljoin}\n".red.bold
        return true
      else
        system args.shelljoin
        result = $?.exitstatus
        exit(result) unless noerror or result == 0
        return result
      end
    end
    def nix(*args, **kargs) run :nix, *args, **kargs end
    def ssh(*args, **kargs) run :ssh, *args, **kargs end
    def scp(*args, **kargs) run :scp, *args, **kargs end

    def optarg key,
               value=options[key],
               flag: key.start_with?("--") ? key : "--#{key}",
               &valueblock
      if options[key]
        if block_given?
          valueblock.call(key, value)
        elsif value == nil
          flag
        else
          [ flag, value ]
        end
      end
    end
  end

  ## Global CLI configuration
  DEFAULT_PROFILE = "/nix/var/nix/profiles/system"
  DEFAULT_REPO = "hlissner/dotfiles"

  class_option :verbose, aliases: '-V', type: :boolean, default: false,
               desc: "Be more verbose about errors and logs"
  class_option :backtrace, aliases: '-T', type: :boolean, default: false,
               desc: "Show backtrace for errors"
  class_option :dryrun, aliases: '-D', type: :boolean, default: false,
               desc: "Don't actually change anything; only pretend"

  class_option :flake, aliases: '-F', banner: "FLAKE_URI", type: :string,
               desc: "What flake to treat as your dotfiles"
  class_option :host, type: :string, desc: "The target host to operate on"
  class_option :user, type: :string, desc: "The primary user's username"
  class_option :color, type: :boolean, default: STDOUT.isatty,
               desc: STDOUT.isatty ? "Suppress ANSI color codes" : "Force ANSI color codes"

  def help *args
    super *args
    shell.say 'Use -h (or --help) with any command for more information.'
  end
end
