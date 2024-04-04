# lib/rb/nixos.rb
#
# Author:  Henrik Lissner
# Version: 0.0.1
##

require_relative 'thor'
require 'json'
require 'shellwords'
require 'fileutils'
require 'open3'
require 'tmpdir'

Flake = Struct.new(:path, :host, :user, :theme) do
  def initialize(uri, host: nil, user: nil, theme: ENV['THEME'], **options)
    options[:theme] ||= ENV['THEME']
    uri = locate(uri || Dir.pwd)
    @explicit = !uri
    if uri ||= File.expand_path('../..', File.dirname(__FILE__))
      if m = uri.match(/^(.+)#(.+)$/)
        path, host = m[1], m[2]
      else
        path = uri
        host ||= `hostname`.chomp
        host = nil if host == "nixos"
        user ||= `whoami`.chomp
        user = nil if user == "root"
      end
      super(File.realpath(File.expand_path(path)), host, user, theme)
    end
  end

  def to_json = to_h.to_json
  def uri = "#{path}##{host}"
  def explicit? = @explicit

  def ensure!
    $stderr.puts "No flake at #{Dir.pwd}. Falling back to #{uri}".red if explicit?
    abort "No flake path specified" unless path
    abort "No flake hostname specified for #{path}" unless host
    abort "Could not find a host config for #{host} in #{path}/hosts" unless File.directory? "#{path}/hosts/#{host}"
  end

  def dotfiles?(dir = path)
    tmpfile = "/tmp/heyerror"
    json = `__HEYARGS="{}" nix flake show --impure --no-warn-dirty --json #{dir} 2>#{tmpfile}`.chomp
    abort "Nix command failed:\n\n#{File.read(tmpfile)}" if $? != 0
    JSON.parse(json).key?("_heyArgs")
  ensure
    File.delete(tmpfile)
  end

  def locate(dir = Dir.pwd)
    loop do
      break if !dir || dir == "/"
      return dir if File.exist?("#{dir}/flake.nix") && dotfiles?(dir)
      dir = File.locate("flake.nix", File.expand_path("..", dir))
    end
  end
end

class NixOSCLI < CLI
  no_commands do
    def invoke_command(command, *)
      # HACK options' keys are strings, which makes them frustrating to
      #   double-splat around. Nowhere in Thor's API is their string-ness
      #   important, so I convert them. This could break in the future.
      ENV['VERBOSE'] ||= '1' if @options[:verbose]
      @options = @options.transform_keys { |k| k.tr('-', '_').to_sym }.freeze
      @flake = Flake.new(@options[:flake], **@options)
      log? do
        log.invoke_command "#{command.name}:",
                           "@flake=#{@flake.to_json}",
                           "@options=#{@options.to_json}"
      end
      super(command, *)
    end

    protected
    def sh(*args, exec: false, packages: [], env: {}, **options)
      unless packages.empty?
        args = ['nix-shell',
                { p: packages.join(' ') },
                { run: Sh.normalize_args(args).shelljoin } ]
      end
      Sh.send(exec ? :exec : :call,
              *args, **@options.slice(:dryrun, :verbose).merge(options),
              env: env.merge({ '__HEYARGS' => @flake.to_json }))
    end
    def sh!(*, **) = sh(*, **, exec: true)
  end

  ## Global CLI configuration
  class_option :verbose, aliases: '-V', type: :boolean, default: false,
               desc: "Be more verbose about errors and logs"
  class_option "--show-trace", aliases: '-T', type: :boolean, default: false,
               desc: "Show backtrace for errors"
  class_option :dryrun, aliases: '-D', type: :boolean, default: false,
               desc: "Don't actually change anything; only pretend"

  class_option :flake, aliases: '-F', banner: "FLAKE_URI", type: :string,
               desc: "What flake to treat as your dotfiles"
  class_option :host, type: :string, desc: "The target host to operate on"
  class_option :user, type: :string, desc: "The primary user's username"
  class_option :color, type: :boolean, default: $stdout.isatty,
               desc: $stdout.isatty ? "Suppress ANSI color codes" : "Force ANSI color codes"

  def help(*)
    super(*)
    shell.say 'Use -h (or --help) with any command for more information.'
  end
end
