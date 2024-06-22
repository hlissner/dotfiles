(import spork/path :export true)
(import spork/json :export true)
(import sh :export true :prefix "")
(import ./lib :export true :prefix "")

# Janet lacks an analogue for 'trap X EXIT'; I emulate this with handle-exit,
# defer, and os/sigaction. However, this causes os/sleep to be uninterruptable.
(def- *exit-handlers* @[])
(defdyn *exit-handled*)

(defn exit [&opt code]
  (default code 0)
  (if (dyn :exit-handled)
    (error [:exit code])
    (os/exit code)))

(defn abort [message & args]
  (echof :error message ;args)
  (exit 127))

(defn not-implemented [& args]
  (abort "Not implemented yet! %q" args))

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
     (os/sigaction :kill (partial ,on-exit :kill) true)
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

(defn- resolve-1 [kind base & args]
  (if (index-of (type base) [:array :tuple])
    (some |(resolve-1 kind $ ;args) base)
    (let [base (if (path/abspath? base) base (path/find base))]
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
                (peg/match (peg! '(+ (* "-" :w*) (* "--" :w*))) arg) (break)
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
                    (when-let [file (path/sibling :file crumb ".janet" ".zsh" ".sh" "")]
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

(defn help [[file & _args] &opt output]
  (unless (path/exists? file)
    (errorf "File does not exist: %s" (path/abbrev file)))
  (with-dyns [*out* (or output stdout)]
    (with [f (file/open file :rn)]
      (let [peg (peg! '(* "#" (between 0 1 " ")))
            buf @""]
        (var line (file/read f :line))
        (unless (string/has-prefix? "#!/" line)
          (abort "Not a script: %s" (path/abbrev file)))
        (while (set line (file/read f :line))
          (unless (string/has-prefix? "#" line)
            (break))
          (buffer/push buf (peg/replace peg "" line)))
        (when (empty? buf)
          (abort "No documentation for %s" (path/abbrev file)))
        (echo (string/chomp buf)))))
    # TODO: Parse these doc headings into table
    # TODO: Search sub-directory for extra subcommands.
  )

(defn- dispatcher-for [rules &opt command & args]
  (unless command (break))
  (let [odd? (odd? (length rules))
        cmd (get (find (fn [[pat dest]]
                         (case (type pat)
                           :function (pat command ;args)
                           :keyword  (= pat (keyword command))
                           :string   (= pat command)
                           :tuple    (if (keyword? (first pat))
                                       (index-of (keyword command) pat)
                                       (peg/match pat command))
                           (abort "Invalid rule pattern: %q" pat)))
                       (if command
                         (partition 2 (slice rules 0 (if odd? -2 -1)))
                         []))
                 1 (cond (not odd?) nil
                         (string? (last rules)) |[:exec (last rules) ;$&]
                         (last rules)))
        spec (case* (type cmd)
               :function (cmd command ;args)
               :struct [:eval cmd ;args]
               :string [:exec cmd ;args]
               :nil nil
               (abort "Invalid rule destination: %q" cmd))]
    (log 2 "dispatcher-for=%q" spec)
    (case (first spec)
      :eval (let [f (in spec 1)]
              (unless (> (length spec) 1)
                (errorf "Invalid eval dispatcher for: %s" command))
              (fn [op]
                (let [{:cmd cmd :file file}
                      (if (struct? f) f {:cmd f :file (dyn :script)})
                      cargs (slice spec 2)]
                  (case op
                    :which (echo (string/join [file ;cargs] " "))
                    :help  (help [file ;cargs])
                    :call  (cmd command ;cargs)))))
      :exec (if-let [pargs (resolve ;(slice spec 1))]
              (fn [op]
                (case op
                  :which (echo (string/join pargs " "))
                  :help (help pargs)
                  :call (os/execute pargs :p)))
              (abort "Unknown command: %q" command))
      (abort "Unknown command: %q" command))))

(defdyn *script* "TODO")
(defdyn *dryrun* "TODO")
(defdyn *debug* "TODO")

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
       ,;(map |(if (index-of $ '[| || & && ; > >> < ^])
                 (string $) $)
              args))
     (,;args)))

(defn- dispatch-1 [file rules & args]
  (let [idx (index-of "--" args -1)
        largs (slice args 0 idx)
        rargs (if (= idx -1) [] (slice args idx -1))
        help? (or (index-of "-h" largs)
                  (index-of "--help" largs))]
    # During compilation, :current-file is relative to the root of the project
    # (which is $DOTFILES_HOME). At runtime, it's an absolute path.
    (setdyn :script (if (path/abspath? file) file (path :home file)))
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
      (with-envvars ["PATH" (string/join exec-path ":")
                     "DOTFILES_HOME" (path :home)]
        (if-let [args [;(filter |(not (index-of $ ["-?" "-??" "-???" "-!" "-h" "--help"])) largs)
                       ;rargs]
                 op (case* (first args)
                      ["h" "help"] :help
                       "which" :which
                       :call)
                 cmd (dispatcher-for rules ;(slice args (if (= op :call) 0 1)))]
          (cmd (if help? :help op))
          (do (echo :error "Subcommand required.\n")
              (help [(dyn :script) ;args] *err*)
              (exit 1)))))))

(defmacro dispatch [rules & args]
  ~(,dispatch-1 ,(dyn :current-file) [,;rules] ;args))

(defmacro hey [& args]
  ~(do (def output @"")
       (def error @"")
       (cond ,(tuple '$? (path :bin "hey") ;args
                      '> '(unquote output)
                      '> '[stderr error])
             (do (when (debug?)
                   (log "stderr: %s" error))
                 (,string/chomp output))
             (string/has-prefix? "error: " error)
             (error (slice error 0 8))
             (do (echo :err (string/chomp error))
                 (,exit 16)))))

(defmacro hey! [& args]
  (tuple 'do? '$? (path :bin "hey") ;args))

(defmacro hey? [& args]
  ~(do (def output @"")
       (def error @"")
       (if ,(tuple '$? (path :bin "hey") ;args
                   '> '(unquote output)
                   '> '[stderr error])
         (do (when (debug?)
               (log "stderr: %s" error))
             (,string/chomp output)))))

(defmacro hey* [& args]
  ~(when-let [out (hey ,;args)]
     (string/split "\n" out)))
