(import spork/path :export true)
(import spork/json :export true)
(import sh :export true)
(import ./lib :export true :prefix "")
(import ./docs :export true :prefix "")

# Janet lacks an analogue for 'trap X EXIT'; I emulate this with handle-exit,
# defer, and os/sigaction. However, this causes os/sleep to be uninterruptable.
# exit and abort live in ./lib, so that ./docs can reach them.
(def- *exit-handlers* @[])

(defmacro- with-handled-exits [& body]
  (defn- on-exit [type]
    (each [handler sig] *exit-handlers*
      (when (index-of sig [:exit type])
        (handler type)))
    (unless (= type :exit)
      (os/exit 1)))
  ~(defer (,on-exit :exit)
     (setdyn :exit-handled true)
     (os/sigaction :int (partial ,on-exit :int) true)
     (os/sigaction :term (partial ,on-exit :term) true)
     # os/exit evades all these signal handlers, as well as defer, so as long as
     # downstream promises to avoid os/exit (and use our exit instead), this
     # won't be an issue.
     (try (do ,;body)
          ([err fib]
           (if (= (first err) :exit)
             (do (,on-exit :exit)
                 (os/exit (in err 1)))
             (propagate err fib))))))

(defn trap [handler &opt sig]
  (array/push *exit-handlers* [handler sig]))

(defmacro os/with-lock [file & body]
  (with-syms [$file]
    ~(let [,$file ,file]
       (log 3 "Locking with %s" ,$file)
       (while (os/stat ,$file :mode)
         (os/sleep 0.25))
       (os/mkdir (,path/dirname ,$file))
       (spit ,$file "")
       (os/touch ,$file)
       (,trap (fn [&] (os/rm ,$file)) :exit)
       ,;body)))

# Where a script's own arguments start, and my path walk stops.
(defn- flag? [arg]
  (peg/match (peg! '(+ (* "-" :w*) (* "--" :w*))) arg))

(defn- resolve-1 [kind base & args]
  (if (index-of (type base) [:array :tuple])
    (some |(resolve-1 kind $0 ;args) base)
    (let [base (if (path/abspath? base) base (or (path/find base) base))]
      (case (os/stat base :mode)
        nil nil
        :file [base ;args]
        :directory
        (do (var depth 0)
            (var target nil)
            (var crumbs @[])
            (each arg args
              (cond
                (= arg "--") (do (-- depth) (break))
                (flag? arg) (break)
                (let [crumb (path/join (or target base) arg)
                      dir (path/sibling :directory crumb "" ".d")]
                  (++ depth)
                  (array/push crumbs crumb)
                  (if dir
                    (set target dir)
                    (do (if (= kind :directory) (-- depth))
                        (break))))))
            (if (= kind :directory)
              [target ;(slice args depth)]
              (do (each crumb (reverse crumbs)
                    (when-let [file (path/sibling :file crumb ;*script-exts* "")]
                      (set target file)
                      (break))
                    (-- depth))
                  (when target
                    [target ;(slice args depth)]))))
        (abort "Invalid file or directory: %s" base)))))

(defn resolve [base & args]
  (resolve-1 :file base ;args))

(defn resolve-dir [base & args]
  (resolve-1 :directory base ;args))

(defn- find-rule
  "Return the [pattern destination] pair in RULES that COMMAND matches, if any."
  [rules command args]
  (find (fn [[pat _]]
          (case (type pat)
            :function (pat command ;args)
            :keyword  (= pat (keyword command))
            :string   (= pat command)
            :tuple    (if (keyword? (first pat))
                        (index-of (keyword command) pat)
                        (peg/match pat command))
            (abort "Invalid rule pattern: %q" pat)))
        (rule-pairs rules)))

(defn- rule-fallback
  ``Return the destination RULES ends with when nothing matches, if it has one.
  A bare string fallback becomes an exec of that command plus the arguments.``
  [rules]
  (when (odd? (length rules))
    (if (string? (last rules))
      |[:exec (last rules) ;$&]
      (last rules))))

(defn- eval-dispatcher
  "Build the op handler for a rule that resolves to Janet code."
  [command spec]
  (unless (> (length spec) 1)
    (errorf "Invalid eval dispatcher for: %s" command))
  (let [f (in spec 1)
        cargs (slice spec 2)]
    (fn [op]
      (let [{:cmd cmd :file file}
            (if (struct? f)
              {:cmd (f :cmd) :file (script-path (f :file))}
              {:cmd f :file (dyn :script)})]
        (case op
          :which (echo (string/join [file ;cargs] " "))
          :help  (help [file ;cargs])
          :dump  (print-specs (if (struct? f) file))
          :call  (cmd command ;cargs))))))

(defn- exec-dispatcher
  "Build the op handler for a rule that resolves to a script on disk."
  [command spec]
  (let [sargs (slice spec 1)
        pargs (unless (empty? sargs) (resolve ;sargs))]
    (unless pargs
      (abort "Unknown command: %q" command))
    (fn [op]
      (case op
        :which (echo (string/join pargs " "))
        :help  (help pargs)
        :dump  (print-specs (first pargs))
        :call  (let [code (os/execute pargs :p)]
                 (unless (zero? code) (exit code))
                 code)))))

(defn- dispatcher-for [rules &opt command & args]
  (unless command (break))
  (let [pair (find-rule rules command args)
        rule (if pair (in pair 1) (rule-fallback rules))
        # with-doc wraps non-struct destinations in {:fn ... :doc ...}. A cmd
        # struct has no :fn, so it falls through to :struct untouched.
        dest (if (and (dictionary? rule) (get rule :fn)) (rule :fn) rule)
        spec (case* (type dest)
               :function (dest command ;args)
               :struct [:eval dest ;args]
               :string [:exec dest ;args]
               :nil nil
               (abort "Invalid rule destination: %q" dest))]
    (log 2 "dispatcher-for=%q" spec)
    (case (first spec)
      :eval (eval-dispatcher command spec)
      :exec (exec-dispatcher command spec)
      (abort "Unknown command: %q" command))))

# Set once by dispatch-1, read everywhere. Also exported as HEYSCRIPT,
# HEYDRYRUN and HEYDEBUG, for the shell scripts downstream of me.
(defdyn *script* "The script hey dispatched to.")
(defdyn *dryrun* "Whether to print commands instead of running them.")
(defdyn *debug* "Verbosity, 0-3. See the -? flags.")

# The flags hey eats before a subcommand ever sees them.
(def- *global-flags* ["-?" "-??" "-???" "-!" "-h" "--help"])

(defn dryrun? []
  (dyn :dryrun false))

(defn debug? [&opt n]
  (<= (or n 1) (dyn :debug -1)))

(defmacro do?
  "A wrapper for janet-sh macros to no-op them if DRYRUN is active."
  [& args]
  ~(if (,dryrun?)
     (,(first args)
       echo "DRYRUN:"
       ,;(map |(if (index-of $0 '[| || & && ; > >> < ^])
                 (string $0) $0)
              args))
     (,;args)))

(defn- dispatch-1 [file rules & args]
  (let [idx (index-of "--" args -1)
        largs (slice args 0 idx)
        rargs (if (= idx -1) [] (slice args idx -1))
        help? (or (index-of "-h" largs)
                  (index-of "--help" largs))]
    (setdyn :script (script-path file))
    (setdyn :dryrun
       (or (index-of "-!" largs)
           (dyn :dryrun (not (empty? (or (os/getenv "HEYDRYRUN") ""))))))
    (setdyn :debug
       (cond (index-of "-???" largs) 3
             (index-of "-??" largs) 2
             (index-of "-?" largs) 1
             (dyn :debug (scan-number (or (os/getenv "HEYDEBUG") "")))))
    # For downstream shell scripts
    (os/setenv "HEYSCRIPT" (dyn :script))
    (os/setenv "HEYDRYRUN" (if (dyn :dryrun) "1"))
    (os/setenv "HEYDEBUG"  (if (dyn :debug) (string (dyn :debug))))
    (with-handled-exits
      (if (debug?)  (log "Enabled debug mode (level=%d)" (dyn :debug)))
      (if (dryrun?) (log "Enabled dry run mode"))
      # For child processes that may not have its environment available (like
      # system units or cronjobs).
      (with-envvars ["PATH" (string/join (exec-path) ":")
                     "DOTFILES_HOME" (path :home)]
        (let [args [;(filter |(not (index-of $0 *global-flags*)) largs)
                    ;rargs]
              op (case* (first args)
                   ["h" "help"] :help
                    "which" :which
                    :call)]
          (cond
            (and (= op :help) (= (get args 1) "--scan"))
            (print-scan ;(slice args 2))

            (and (= op :help) (= (get args 1) "--dump"))
            (if-let [command (get args 2)
                     cmd (dispatcher-for rules ;(slice args 2))]
              (cmd :dump)
              (print-commands rules))

            (if-let [cmd (dispatcher-for rules ;(slice args (if (= op :call) 0 1)))]
              (cmd (if help? :help op))
              (do (echo :error "Subcommand required.\n")
                  (help [(dyn :script) ;args] *err*)
                  (echo "\nCOMMANDS:")
                  (echo (format-commands rules))
                  (exit 1)))))))))

(defmacro dispatch [rules & args]
  ~(,dispatch-1 ,(dyn :current-file) [,;rules] ;args))

# Resolved on $PATH instead of absolute path b/c hey is compiled ahead of time
# now (see modules/hey.nix).
(def- *hey-bin* "hey")

# These three expand to sh/$?, which resolves wherever they are *used*, not here
# -- so the namespaced spelling is the one that has to travel, and it does, via
# the re-export above. Callers needs only `(use hey)`.
(defmacro hey [& args]
  ~(do (def output @"")
       (def errout @"")  # naming this `error` would shadow the function
       (cond ,(tuple 'sh/$? *hey-bin* ;args
                      '> '(unquote output)
                      '> '[stderr errout])
             (do (when (debug?)
                   (log "stderr: %s" errout))
                 (,string/chomp output))
             (string/has-prefix? "error: " errout)
             (error (,string/no-prefix "error: " (,string/chomp errout)))
             (do (echo :err (,string/chomp errout))
                 (,exit 16)))))

(defmacro hey! [& args]
  (tuple 'do? 'sh/$? *hey-bin* ;args))

(defmacro hey? [& args]
  ~(do (def output @"")
       (def errout @"")
       (if ,(tuple 'sh/$? *hey-bin* ;args
                   '> '(unquote output)
                   '> '[stderr errout])
         (do (when (debug?)
               (log "stderr: %s" errout))
             (,string/chomp output)))))

(defmacro hey* [& args]
  ~(when-let [out (hey ,;args)]
     (string/split "\n" out)))
