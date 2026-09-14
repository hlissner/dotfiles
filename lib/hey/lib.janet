(import spork/path)
(import spork/json)

(def fmt string/format)

(defmacro ignore-errors
  "Like protect, but returns the result of BODY or nil on errors."
  [& body]
  ~(try (upscope ,;body) ([err fib] nil)))

(defmacro peg!
  "Compile static PAT at compile-time and return it."
  [pat]
  (eval ~(peg/compile ,pat)))

(defmacro with-envvars [args & body]
  (let [xs (struct ;args)
        $old (gensym)]
    ~(let [,$old ,(struct ;(catseq [[k _] :pairs xs] [k ~(os/getenv ,k)]))]
       (defer (do ,;(catseq [k :keys xs] [~(os/setenv ,k (get ,$old ,k))]))
         ,;(catseq [[k v] :pairs xs] [~(os/setenv ,k ,v)])
         ,;body))))

(defmacro with-umask [umask & body]
  ~(let [old (os/umask ,umask)]
     (defer (os/umask old)
       ,;body)))

(def- *atomic-types*
  {:nil true
   :boolean true
   :number true
   :string true
   :buffer true
   :symbol true
   :keyword true})

(defn atom?
  "Return non-nil if VALUE is an atomic type."
  [value]
  (get *atomic-types* (type value) false))

(defn tuple/type? [val type]
  (and (tuple? val)
       (or (nil? type)
           (= (tuple/type val) type))))

(defn case-body
  ``Expand CLAUSES, a list of pattern/body pairs with an optional fallback, into
  the body of a cond. Use TESTFN to test each pattern.``
  [testfn clauses]
  (def fallback (if (odd? (length clauses)) (last clauses)))
  [;(catseq [[pred body] :in (partition
                              2 (if fallback (slice clauses 0 -2) clauses))]
      [(testfn pred) body])
   fallback])

(defmacro case*
  "Like case, but dispatch values can be tuples to represent one-off matches."
  [value & clauses]
  (with-syms [$var]
    ~(let [,$var ,value]
       (cond ,;(case-body (fn [pred]
                            (if (tuple/type? pred :brackets)
                              ~(index-of ,$var ,pred)
                              ~(= ,$var ,pred)))
                          clauses)))))

(defn array/remove-elt [arr elt &opt all?]
  (var idx nil)
  (while (set idx (index-of elt arr))
    (array/remove arr idx)
    (unless all? (break)))
  arr)

(defn take! [n ind]
  (let [val (take n ind)
        len (length val)]
    (unless (zero? len) (array/remove ind 0 len))
    val))

(defn take-while! [pred ind]
  (let [val (take-while pred ind)
        len (length val)]
    (unless (zero? len) (array/remove ind 0 len))
    val))

(defn string/chomp [str]
  (if (string/has-suffix? "\n" str)
    (slice str 0 -2)
    (string str)))

(defn string/no-suffix [suffix str]
  (if (string/has-suffix? suffix str)
    (slice str 0 (- -1 (length suffix)))
    str))

(defn string/no-prefix [prefix str]
  (if (string/has-prefix? prefix str)
    (slice str (length prefix) -1)
    str))

(def- *colors*
  {:r "\e[31m"
   :g "\e[32m"
   :y "\e[33m"
   :warn "\e[33m⚠ "
   :error "\e[31m𐄂 "
   :check "\e[32m✓ "
   :debug "\e[34m"
   :reset "\e[0m"})

(defn echo [& args]
  (var args (array ;args))
  (var format :raw)
  (var color nil)
  (var output stdout)
  (def flags (take-while! keyword? args))
  (each k flags
    (case* k
      :raw  (set format :raw)
      :json (set format :json)
      :err  (set output stderr)
      [:error :warn :debug] (do (set output stderr)
                                (set color k))
      (set color k)))
  (case (length args)
    0 nil
    1 (when-let [val (first args)]
        (with-dyns [*out* output]
          (case format
            :raw (printf (if (atom? val) "%s%V%s" "%s%m%s")
                         (or (get *colors* color) "")
                         val
                         (if color "\e[0m" ""))
            :json (print (json/encode val "  " "\n"))
            (errorf "Invalid format: %s" format))))
    (each v args
      (echo ;flags v))))

(defn echof [& args]
  (def args (array ;args))
  # take-while! mutates args, so pull out the flags before reading the format
  # string from what's left.
  (def flags (take-while! keyword? args))
  (echo ;flags (string/format (first args) ;(slice args 1))))

# init.janet's with-handled-exits turns :exit-handled on, so that exit unwinds
# through its handlers instead of leaving them unrun. These live here rather
# than beside it so docs.janet can reach them without importing init.
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

(def *script-exts*
  ``Extensions hey recognizes on a dispatchable script, in order.``
  [".janet" ".zsh" ".sh"])

(defn path/no-ext
  "Remove any (or a specific) file extension from PATH."
  [path & exts]
  (or (when-let [ext (path/ext path)]
        (when (or (empty? exts) (index-of ext exts))
          (string/no-suffix ext path)))
      path))

(defn path/sibling [type path & exts]
  (when-let [base (path/no-ext path ;exts)
             ext (find |(= (os/stat (string base $0) :mode) type)
                       exts)]
    (string base ext)))

(defn path/files-in
  "Like os/dir, but returns a list of absolute paths."
  [dir]
  (map |(path/join dir $0) (os/dir dir)))

(defn path/abbrev "Replace /home/$USER to ~ in PATH."
  [path]
  (peg/replace (peg! ~(* ,(os/getenv "HOME"))) "~" path))

(defn path/executable?
  "Return true if PATH exists and is executable."
  [path]
  (when-let [perms (os/stat path :int-permissions)]
    (not= 0 (band perms 8r111))))

(defn path/exists? [path]
  (truthy? (os/stat path :mode)))

(defn path/file? [path]
  (= (os/stat path :mode) :file))

(defn path/directory? [path]
  (= (os/stat path :mode) :directory))

(defn path/symlink? [path]
  # os/stat follows the link, so a dangling symlink would report nil.
  (= (os/lstat path :mode) :link))

(def- *xdg*
  (delay {:bin     (os/getenv "XDG_BIN_HOME")
          :config  (os/getenv "XDG_CONFIG_HOME")
          :data    (os/getenv "XDG_DATA_HOME")
          :cache   (os/getenv "XDG_CACHE_HOME")
          :state   (os/getenv "XDG_STATE_HOME")
          :runtime (os/getenv "XDG_RUNTIME_DIR")
          :fake    (os/getenv "XDG_FAKE_HOME")}))

(defn path/xdg [key & args]
  (path/join (or (get (*xdg*) key)
                 (errorf "Invalid XDG directory: %s" key))
             ;args))

(def- *flake-info*
  # Generated by modules/hey.nix. Deferred like *xdg* and *flake* below, so a
  # missing info.json doesn't break every import of hey.
  (delay (json/decode (slurp (path/xdg :data "hey/info.json"))
                      :keywords true)))

(defn flake/info [& args]
  (get-in (*flake-info*) args))

(def- *flake*
  (delay {:path  (os/realpath
                  (or (os/getenv "DOTFILES_HOME")
                      (error "DOTFILES_HOME not set")))
          :user  (os/getenv "USER")
          :host  (or (os/getenv "HOST") (string/chomp (slurp "/etc/hostname")))}))

(defn flake [&opt key]
  (if key (get (*flake*) key) (*flake*)))

(defn flake/json []
  (string (json/encode (flake))))

(def exec-path
  (distinct
   # Generated by modules/hey.nix. The janet script may be executed from an
   # environment where PATH isn't properly set up (like a systemd service).
   @[(os/realpath (path/join (dyn :syspath) "../bin"))
     (path/xdg :bin)
     ;(let [pfile (path/xdg :data "hey/path")]
        (if (path/file? pfile)
          (string/split ":" (string/trimr (slurp pfile)))
          ["/run/wrappers/bin"
           (string/format "/etc/profiles/per-user/%s/bin" (flake :user))
           "/run/current-system/sw/bin"]))
     ;(string/split ":" (os/getenv "PATH"))]))

(defn path/find
  "Find executable NAME in PATHS (defaults to $PATH)."
  [name &opt paths]
  (if (path/abspath? name)
    (if (path/exists? name) name)
    (some |(let [p (path/join $0 name)]
             (if (os/stat p :mode) p))
          (or paths exec-path))))

(defn- wm []
  (let [desktop (string/ascii-lower (os/getenv "XDG_CURRENT_DESKTOP"))]
    (cond (string/find "hyprland" desktop) :hypr
          (= desktop nil) (error "XDG_CURRENT_DESKTOP not set")
          (errorf "Unrecognized desktop: %s" desktop))))

(def- *paths*
  {:home     [|(flake :path)]
   :assets   [:home "assets"]
   :bin      [:home "bin"]
   :cache    [|(path/xdg :cache "hey")]
   :config   [:home "config"]
   :data     [|(path/xdg :data "hey")]
   :hosts    [:home "hosts"]
   :host     [:hosts |(or (flake :host) (error "HOST is not set"))]
   :lib      [:home "lib"]
   :modules  [:home "modules"]
   :runtime  [|(path/xdg :runtime "hey")]
   :state    [|(path/xdg :state "hey")]
   :test     [:home "test"]
   :wm       [:config wm]
   :wm*      [|(path/xdg :config) wm]
   :profile  ["/nix/var/nix/profiles/system"]
   :profile* [|(path/xdg :state "nix/profiles/profile")]})

(defn path "Return a path to an area within my dotfiles."
  [area & args]
  (path/join
   ;(let [segments (if (string? area) [(path/abspath area)] (get *paths* area))]
      (catseq [p :in (or segments (errorf "Unknown area: %s" area))]
        (case (type p)
          :keyword (path p)
          :function (or (p) (errorf "Path segment function returns nil in %s" area))
          :nil []
          [p])))
   ;args))

(defmacro log
  "Print MESSAGE to stderr, but only at debug LEVEL (1 by default) or above."
  [& args]
  (def leveled? (number? (first args)))
  (def level    (if leveled? (first args) 1))
  (def message  (in args (if leveled? 1 0)))
  (def args     (slice args (if leveled? 2 1)))
  ~(when (>= (dyn :debug -1) ,level)
     (with-dyns [*out* stderr]
       (echof :debug (string "LOG[%s]: " ,message)
              ,(path/no-ext
                (path/join ;(slice (path/parts (dyn :current-file)) -3 -1)))
              ,;args))))

(defn opts
  "Return ARGS (a tuple) if no element is nil. An empty tuple otherwise."
  [& args]
  (if (every? args) (map string args) []))
