# lib/lib.rb
#
# This is the shared library all my ruby scripts use. Why ruby? Because bash/zsh
# are awful for needs as convoluted as mine, and I like ruby more than perl, and
# much *much* more than python.

require 'shellwords'
require 'fileutils'
require 'pp'

# Add $PWD/lib to LOAD_PATH, so other scripts can load our (namespaced) 'rb/*'
# scripts simply
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require_relative 'rb/notify'
require_relative 'rb/sh'

## Often referenced constants
XDG_CONFIG_HOME = ENV['XDG_CONFIG_HOME']
XDG_DATA_HOME = ENV['XDG_DATA_HOME']
XDG_RUNTIME_DIR = ENV['XDG_RUNTIME_DIR'] || '/tmp'

DOTFILES_DIR = ENV['DOTFILES_HOME']
DOTFILES_CONFIG_DIR = "#{DOTFILES_DIR}/config"
DOTFILES_THEMES_DIR = "#{DOTFILES_DIR}/modules/themes"
DOTFILES_THEME_DIR = "#{ENV['DOTFILES_THEME_HOME']}"

# Pipe uncaught exceptions to notify-send (or rofi), since these libraries will
# likely be used as part of a GUI, where stderr won't be visible.
at_exit do
  if $!.is_a?(StandardError)
    e = $!
    begin
      message = e.message.gsub(/#<([^:]+):0x.+> \(/, '#<\1>').escape_html
      trace = e.backtrace.join("\n").gsub(ENV['HOME'], "~").escape_html
      # Rofi is better suited to displaying giant walls of text than dunst.
      if Sh.executable?('rofi')
        system(['rofi', '-markup', '-e',
                "<b>Uncaught #{e.class} exception</b>\n\n<tt>#{message}\n\n<small>#{trace}</small></tt>"]
                 .shelljoin + ' &')
      else
        Notify.error "#{message}\n\n<tt>#{trace}</tt>", title: e.class.to_s, app: File.basename($0)
      end
    rescue Exception => e
      $stderr.puts "Uncaught #{e.class} exception: #{e.message}"
    end
  end
end


## Shared library
XDATA = {}
def xrdb_get(id)
  XDATA[id] ||= `xrdb -get #{id.is_a?(Integer) ? "color#{id}" : id}`.chomp
end

START = Time.now.to_f
def log = Log.new
def log? = ENV['VERBOSE'] ? yield : false

class Log
  START = Time.now.to_f

  def [](id); send(id); end

  # FIXME: Rushed. Refactor me.
  def method_missing(method, *args, **opts)
    @label = [] unless @label
    @label.push(method)
    unless args.empty? && opts.empty?
      color = :blue
      if @label.any? { |l| l.end_with?('!') }
        color = :red
      elsif @label.any? { |l| l.end_with?('?') }
        unless ENV["VERBOSE"]
          @label = []
          return self
        end
      end
      prefix = sprintf(
        "%0.6f:".bold + " %s: ".send(color),
        Time.now.to_f - START,
        @label.map { |l| l.to_s.sub(/[!?]$/, '') }.join("."))
      $stderr.write(prefix)
      indent = " " * prefix.strip_ansi.size
      max_col = 79
      max_col_adjusted = 79 - indent.size
      if args.size == 1 && !args[0].one_of?(Array, Hash)
        str = args[0].is_a?(String) ?
                args[0] :
                PP.pp(args[0], '', max_col).gsub("\n", "\n#{indent}").strip
        str << "\n"
      else
        col = 0
        str = ""
        args.each do |arg|
          if arg.one_of?(Hash, Array)
            case str[-1]
            when "\n" then str << indent
            when NilClass
            else str << " "
            end
            pstr = PP.pp(arg, '', max_col_adjusted).strip
            if pstr[/\n/]
              str << "\n#{indent}" if str[-1]
              pstr.gsub!(/\n/, "\n#{indent}")
            end
            str << pstr
          else
            argstr = arg.to_s
            if col != 0
              if (col + argstr.size) >= max_col_adjusted
                str << "\n#{indent}"
                col = 0
              else
                str << " "
                col += 1
              end
            end
            col += argstr.size
            str << argstr
          end
        end
        str << "\n" unless str == ""
      end
      opts.each do |k,v|
        case str[-1]
        when "\n" then str << indent
        when NilClass
        end
        prefix = "#{k} => "
        str << prefix
        str << PP.pp(v, '', 79 - prefix.size).gsub("\n", "\n#{indent}#{' ' * prefix.size}").rstrip
        str << "\n"
      end
      $stderr.puts(str) unless str == ""
      @label = []
    end
    self
  end
end


## Quick and easy persisted (and auto-expiring) data
PersistentData = Struct.new(:path, :ttl, :time, :pid, :data, :default, keyword_init: true) do
  def self.load(path, default: {}, ttl: nil)
    begin
      data = Marshal.load(File.read(path)) if File.exist?(path)
    rescue StandardError => e
      $stderr.puts "Error: failed to load #{path}: #{e.message}"
      data = nil
    end
    now = Time.now.to_i
    d = PersistentData.new(**(data || {}))
    d.default = default
    d.data ||= default
    d.time ||= now
    d.path = path
    d.ttl  = ttl
    d.expire if d.ttl and d.time + d.ttl > now.to_i
    d
  end

  def [](key); self.data[key]; end
  def []=(key, value); self.data[key] = value; end

  def expire
    self.data = self.default
    File.delete(self.path) if File.exist?(self.path)
    Process.try_kill(15, pid)
  end

  def expire_later(ttl = self.ttl, &)
    Process.try_kill(15, pid) if pid
    self.pid = fork do
      Signal.trap('TERM') { throw :terminate }
      catch :terminate do sleep ttl; end
      yield(self, data) if block_given?
      expire
    end
  end

  def save(data = nil)
    self.data = data if data
    self.time = Time.now.to_i
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'wb') do |f|
      f.chmod(0600)
      f.write(Marshal.dump(to_h))
    rescue StandardError => e
      $stderr.puts "Error: failed to write #{path}: #{e.message}"
      expire
    end
  end
end


## Interaction with clipboard
module Clipboard
  module_function
  @value = nil
  @pid = nil

  def out(**)
    out, code = xclip('-out', **)
    abort "Failed to read to clipboard: #{out}" unless code == 0
    out
  end

  def in=(data); self.in(data); end

  def in(data, **)
    out, code = xclip('-in', **, input: data)
    abort "Failed to write to clipboard: #{out}" unless code == 0
    @value = out
  end

  def in_file(file, **)
    out, code = xclip('-in', file, **)
    abort "Failed to write to clipboard: #{out}" unless code == 0
    @value = out
  end

  def clear = xclip('-in', '/dev/null')

  def auto_expire(ttl=3600)
    @pid = fork do
      Signal.trap('TERM') { throw :terminate }
      catch :terminate do; sleep ttl; end
      clear if out == @value
    end
  end

  private def xclip(*, selection: 'clipboard', type: 'text/plain', input: nil)
    sh('xclip', '-selection', selection, '-t', type, *, input:, discard_output: true)
  end
end


## Monkey patches
class Object
  # Pseudo-lexical scoping
  def let(bindings, &block)
    s = Struct.new(*bindings.keys).new(*bindings.values)
    s.instance_eval(&block)
  end

  # Raise an TypeError if VALUE is not one of TYPES.
  #
  # @param types [Array<Class>] a list of classes (or objects whose classes is used) to test against
  # @raise [ArgumentError] if value is not one of types
  def assert_type!(*types)
    unless types.any? { |t| is_a?(t.is_a?(Class) ? t : t.class) }
      raise TypeError, "Expected #{types.join('|')}, got #{self.class}"
    end
    true
  end

  def as(*types, null: nil)
    one_of?(*types) ? self : null
  end

  def as!(*types)
    assert_type!(*types)
    self
  end

  # A variadic is_a?
  #
  # @param types [Array<Class, #class>] a list of classes or values (whose classes) are tested against
  # @return [true, false] true if is_a? satifies one of the types
  def one_of?(*)
    assert_type!(*)
  rescue TypeError
    false
  end

  # If this value is falsy (or is empty), execute the given block or
  # return the given arguments.
  #
  # TODO
  def else(*args, &)
    if !self || (self.respond_to?(:empty?) && self.empty?)
      if block_given?
        yield(*args)
      else
        args.size > 1 ? args : args[0]
      end
    end
  end

  # Convert a boolean value to string "yes" or "no", returning itself otherwise.
  #
  # @param yes [Any] returned if this is a TrueClass (default: "yes")
  # @param no [Any] returned if this is a FalseClass (default: "no")
  # @param fallback [Any] returned if value is neither true or false
  # @return [Any] returns yes or no if value is a boolean, returns value otherwise
  def to_yn(yes: 'yes', no: 'no', fallback: self)
    case self
    when true then yes
    when false then no
    else fallback
    end
  end
end

# So Boolean types can be tested for explicitly and concisely, in a #is_a? call
module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

class Hash
  def to_struct
    Struct.new(*keys.map(&:to_sym)).new(*values)
  end
  def deep_dup
    Marshal.load(Marshal.dump(self))
  end
end

class Array
  def to_struct
    map do |v|
      case v
      when v.respond_to?(:to_struct) then v.to_struct
      when v.respond_to?(:to_h) then v.to_h.to_struct
      else v
      end
    end
  end

  def join_or_nil(str) = nil? ? nil : join(str)
end

class File
  def self.locate(file, dir = Dir.pwd)
    loop do
      break if dir == '/'
      return dir if exist?("#{dir}/#{file}")
      dir = expand_path('..', dir)
    end
  end
end

class String
  def truncate(max, ellipsis: "…")
    return self if size <= max
    "#{self[0..(max - ellipsis.size)].rstrip}#{ellipsis}"
  end

  def escape_html
    self.gsub('&', "&amp;")
        .gsub('<', "&lt;")
        .gsub('>', "&gt;")
  end

  def /(path) = File.expand_path(path, self)

  # Ansi colors
  def black         = wrap(30)
  def red           = wrap(31)
  def green         = wrap(32)
  def brown         = wrap(33)
  def blue          = wrap(34)
  def magenta       = wrap(35)
  def cyan          = wrap(36)
  def gray          = wrap(37)
  def bold          = wrap(1, 22)
  def italic        = wrap(3, 23)
  def underline     = wrap(4, 24)
  def reverse_color = wrap(7, 27)
  def color?        = STDOUT.isatty

  def strip_ansi = gsub(/\e\[[0-9;]+m/, '')

  private
  def wrap(code, b=0)
    color? ? "\e[#{code}m#{self}\e[#{b}m" : self
  end
end

module Process
  def self.running?(pid)
    getpgid(pid)
    true
  rescue Errno::ESRCH
    false
  end

  def self.alive?(pid)
    running?(pid) and File.read("/proc/#{pid}/stat", 64).split[2] != 'Z'
  end

  def self.try_kill(signal, pid = 0)
    kill(signal, pid) if pid && running?(pid)
  end
end

class Method
  # Returns all the explicit keyword parameters of a method.
  def keyword_parameters(binding)
    parameters.map do |type, name|
      if type == :key
        [ name, binding.local_variable_get(name) ]
      end
    end.compact!.to_h
  end
end

class Proc
  def to_lambda
    return self if lambda?
    old_self = self
    method = Module.new.module_exec do
      instance_method(define_method(:_, &old_self))
    end
    lambda do |*args, &block|
      method
        .bind(self == old_self ? old_self._receiver : self)
        .call(*args, &block)
    end
  end

  def _receiver = binding.eval("self")
end


class Time
  def parse
    require 'chronic'
  end

  def relative_to(time, short = false)
    years = time.year - self.year
    months = time.month - self.month

    diff = (time - self).round
    past = diff < 0
    diff = diff * -1 if past

    # weeks = ((diff / (60 * 60 * 24)) / 7) % 4
    days = (diff / (60 * 60 * 24)) % 7
    hours = (diff / (60 * 60)) % 24
    minutes = ((diff % 3600) / 60) % 60
    seconds = diff % 60

    pluralize = ->(n, word, pword = nil) do
      if n != 1
        pword ||= word.size > 1 ? "#{word}s" : word
        word = pword
        word = " #{word}" if word.size > 1
      end
      "#{n}#{word}"
    end
    parts = []
    parts << pluralize.call(years.abs,   short ? "Y" : "year")   if years != 0
    parts << pluralize.call(months.abs,  short ? "M" : "month")  if months != 0
    # parts << pluralize.call(weeks.abs,   short ? "w" : "week")   if weeks != 0
    parts << pluralize.call(days.abs,    short ? "d" : "day")    if days != 0
    parts << pluralize.call(hours.abs,   short ? "h" : "hour")   if hours != 0
    parts << pluralize.call(minutes.abs, short ? "m" : "minute") if minutes != 0
    parts << pluralize.call(seconds.abs, short ? "s" : "second") if seconds != 0

    return "now" if parts.empty?
    parts[-1] = "and #{parts[-1]}" if parts.size > 1
    parts.join(', ') + (past ? " ago" : "")
  end

  def self.parse(input, short: false)
    return if input.strip.empty?
    i = 0
    result = { y: nil, M: nil, d: nil, h: nil, m: nil, s: nil, }
    table  = { d: 24 * 60 * 60, h: 60 * 60, m: 60, s: 1, }
    input.scan(/[^ ]+/) do |word|
      case word
      when /^(\d{4}|\d{1,2}(:\d{2})?[ap]m)$/
        unless result.except(:exact).compact.empty?
          raise ArgumentError, "Cannot specify both an absolute and relative time"
        end
        i += word.size + 1
        return Chronic.parse(word), (input[i..]&.strip).to_s
      when /^(-?\d+)([smMhdwy]|min|sec|hrs?|weeks?|days?|mo|yrs?|years?)$/
        sym = ['mo', 'M'].include?($2) ? :M : $2[0].to_sym
        result[sym] = $1.to_i * (table[sym] || 1)
        i += word.size + 1
      else
        break
      end
    end
    raise ArgumentError, "Cannot parse time in put" if result.compact.empty?
    diff = result.except(:y, :M).values.compact.sum
    gettime = ->(n, label, now) do
      return now unless n
      past = n < 0
      str = past ? "#{n.abs} #{label} ago" : "in #{n.abs} #{label}"
      return Chronic.parse(str, now:, context: past ? :past : nil)
    end
    now = Time.now
    now = gettime.call(result[:M], 'months', now)
    now = gettime.call(result[:y], 'years', now)
    return gettime.call(diff, 'seconds', now),
           (input[i..]&.strip).to_s
  end
end
