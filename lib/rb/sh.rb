# lib/rb/sh.rb

# Convenience aliases
def sh(*, **, &)  = Sh.call(*, **, &)
def sh!(*, **, &) = Sh.exec(*, **, &)

module Sh
  module_function

  @@pids = []
  @@env = {}
  def [](key) = @@env[key]
  def []=(key, val); @@env[key] = val; end
  def cleanup!
    Process.try_kill(3, @@pids.pop) until @@pids.empty?
  end
  # All functions in this module are blocking by design, so their child
  # processes ought to be killed if the parent is prematurely terminated (e.g.
  # due to a crash or SIGTERM).
  at_exit { Sh.cleanup! }

  # Executes a shell command, but ties its life to the calling ruby script.
  #
  # TODO
  def call(*args,
           env: args[0].is_a?(Hash) ? args.shift : {},
           input: nil,
           dryrun: !!env[:DRYRUN],
           verbose: !!env[:VERBOSE],
           discard_output: false,
           stderr: false,
           redirect: nil,
           append: nil,
           pipe: nil)
    env = @@env.merge(env).compact.transform_keys(&:to_s)
    args = normalize_args(args, env)
    args.push(">#{redirect.shellescape}") if redirect
    args.push(">>#{append.shellescape}") if append
    args.push("| #{pipe.shellescape}") if pipe
    if dryrun or verbose
      (verbose ? $stdout : $stderr).puts "[sh] $ #{args.join ' '}"
      return 0 if dryrun
    end
    [
      IO.popen(env, args, input ? 'w+' : 'r',
               err: stderr ? [:child, :out] : $stderr) do |io|
        @@pids.push(io.pid)
        if input
          io.write(input)
          io.close_write
        end
        io.read&.chomp unless discard_output
      ensure
        @@pids.delete(io.pid)
        # Needed in case its caller is terminated (i.e. in a thread)
        io.close unless io.closed?
      end || '',
      $?.exitstatus
    ]
  end

  # Like #call, but pipes output directly to the shell, and does not capture its
  # output. Takes after execve.
  #
  # TODO
  # @return [Integer] exit code
  def exec(*args,
           env: args[0].is_a?(Hash) ? args.shift : {},
           input: nil,
           noerror: false,
           dryrun: !!env[:DRYRUN],
           verbose: !!env[:VERBOSE])
    env = @@env.merge(env).compact.transform_keys(&:to_s)
    args = normalize_args(args, env)
    if dryrun or verbose
      (verbose ? $stdout : $stderr).puts "[sh] $ exec #{args.shelljoin}"
      return 0 if dryrun
    end
    system env, *args
    code = $?.exitstatus || 1
    exit(code) unless noerror or code == 0
    code
  rescue Interrupt
    abort "Aborting..."
  end

  # Launch and detach a co-process.
  #
  # TODO
  # @return [Integer] The PID of the co-process.
  def coproc(*args,
             env: args[0].is_a?(Hash) ? args.shift : {},
             input: nil,
             noerror: false,
             dryrun: !!env[:DRYRUN],
             verbose: !!env[:VERBOSE])
    env = @@env.merge(env).compact.transform_keys(&:to_s)
    args = normalize_args(args, env)
    if dryrun or verbose
      log.sh.coproc args
      return -1 if dryrun
    end
    pid = fork do
      env.each { |k,v| ENV[k] = v }
      exec(*args)
    end
    Process.detach(pid)
    pid
  end

  # Flattens args into an argument list, suitable for executing on the shell.
  #
  # Enables a succinct semi-DSL for building argument lists.
  #
  # TODO
  def normalize_args(args, env={}, mapfn=:itself)
    return [] if args.empty?
    arg, *rest = args
    [
      *(case arg
        when false, [], {}, nil then []
        when 'sudo', :sudo
          if env.empty?
            arg
          else
            keys = env.keys
            env = {}  # only normalize first 'sudo'
            [arg, "--preserve-env=#{keys.join(',')}"]
          end
        when String then arg
        when Array then normalize_args(arg, env)
        when Hash
          normalize_args(
            arg.flat_map do |k,v|
              if k.is_a?(Symbol)
                k = k.size > 1 ? "--#{k}" : "-#{k}"
              end
              unless [false, [], {}, nil].include?(v)
                [k, *(v == true ? nil : normalize_args(v, env))]
              end
            end,
            env
          )
        else arg.to_s
        end),
      *normalize_args(rest, env)
    ]
  end

  EXE = {}
  # Return true if an executable is in your $PATH.
  #
  # @param exe String the name (or path) to an executable
  # @return [Boolean]
  def executable?(exe)
    (EXE[exe] ||= `which #{exe} 2>/dev/null`.chomp) != ""
  end

  # Checks if an executable is in your $PATH, aborting the program otherwise.
  #
  # @param exe [String] the name (or path) to an executable
  # @return [true] if so
  def assert_executable!(exe)
    executable?(exe) or raise "Couldn't find #{exe} in PATH"
    true
  end
end
