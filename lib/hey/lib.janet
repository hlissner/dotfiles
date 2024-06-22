(import spork/path)
(import spork/json)

# % and mod are both modulo functions. We don't need two, so I take over one of
# them for this common use-case:
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

(defn falsey? [val]
  (or (not val)
      (ignore-errors (empty? val))))

(defn tuple/type? [val type]
  (and (tuple? val)
       (or (nil? type)
           (= (tuple/type val) type))))

(defmacro case*
  "Like case, but dispatch values can be tuples to represent one-off matches."
  [value & clauses]
  (let [fallback (if (odd? (length clauses)) (last clauses))
        $var (gensym)]
    ~(let [,$var ,value]
       (cond ,;(reduce
                 (fn [init [pred body]]
                   (array/concat
                    init ~(,(if (tuple/type? pred :brackets)
                              ~(index-of ,$var ,pred)
                              ~(= ,$var ,pred))
                            ,body)))
                 @[] (partition
                      2 (if fallback (slice clauses 0 -2) clauses)))
               ,fallback))))

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

(defn take-until! [pred ind]
  (let [val (take-until pred ind)
        len (length val)]
    (unless (zero? len) (array/remove ind 0 len))
    val))

(defn drop! [n ind]
  (let [val (drop n ind)
        len (length val)]
    (unless (zero? len) (array/remove ind 0 len))
    val))

(defn drop-while! [pred ind]
  (let [val (drop-while pred ind)
        len (length val)]
    (unless (zero? len) (array/remove ind (- len) len))
    val))

(defn drop-until! [pred ind]
  (let [val (drop-until pred ind)
        len (length val)]
    (unless (zero? len) (array/remove ind (- len) len))
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
  (each k (take-while! keyword? args)
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
      (echo format ;(if color [color] []) v))))

(defn echof [& args]
  (var args (array ;args))
  (echo ;(take-while! keyword? args)
         (string/format (first args) ;(slice args 1))))

(defn path/no-ext
  "Remove any (or a specific) file extension from PATH."
  [path & exts]
  (if (empty? exts)
    (string/join (slice (string/split "." path) 0 -2) ".")
    (or (when-let [ext (path/ext path)]
          (when (index-of ext exts)
            (string/no-suffix ext path)))
        path)))

(defn path/sibling [type path & exts]
  (when-let [base (path/no-ext path ;exts)
             ext (find |(= (os/stat (string base $) :mode) type)
                       exts)]
    (string base ext)))

(defn path/files-in
  "Like os/dir, but returns a list of absolute paths."
  [dir]
  (map |(path/join dir $) (os/dir dir)))

(defn path/abbrev "Replace /home/$USER to ~ in PATH."
  [path]
  (peg/replace (peg! ~(* ,(os/getenv "HOME"))) "~" path))

(defn path/executable?
  "Return true if PATH exists and is executable."
  [path]
  (when-let [perms (os/stat path :permissions)]
    # TODO: Use bitwise ops instead
    (and (find |(= (chr "x") (get perms $)) [2 5 8])
         true)))

(defn path/exists? [path]
  (truthy? (os/stat path :mode)))

(defn path/file? [path]
  (= (os/stat path :mode) :file))

(defn path/directory? [path]
  (= (os/stat path :mode) :directory))

(defn path/symlink? [path]
  (and (os/stat path :mode)
       (ignore-errors (os/readlink path))))

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
  # Generated by modules/hey.nix
  (json/decode (slurp (path/xdg :data "hey/info.json"))
               :keywords true))

(defn flake/info [& args]
  (get-in *flake-info* args))

(def- *flake*
  (delay {:path  (or (os/getenv "DOTFILES_HOME") (error "DOTFILES_HOME not set"))
          :user  (os/getenv "USER")
          :host  (or (os/getenv "HOST") (string/chomp (slurp "/etc/hostname")))
          :theme (or (os/getenv "THEME") (flake/info :theme :active))}))

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
    (some |(let [p (path/join $ name)]
             (if (os/stat p :mode) p))
          (or paths exec-path))))

(defn- wm []
  (let [desktop (os/getenv "XDG_CURRENT_DESKTOP")]
    (case desktop
      "Hyprland" :hypr
      "bspwm"    :bspwm
      nil        (error "XDG_CURRENT_DESKTOP not set")
      (errorf "Unrecognized desktop: %s" desktop))))

(def- *paths*
  {:home     [|(flake :path)]
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
   :themes   [:modules "themes"]
   :theme    [:themes |(or (flake :theme) (error "No active theme"))]
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

(defmacro log [& args]
  (var args (array ;args))
  (var message (first args))
  (var level 1)
  (take! 1 args)
  (when (number? message)
    (set level message)
    (set message (first args))
    (take! 1 args))
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

(defn plist/index [plist key]
  (label result
    (each i (range 0 (/ (length plist) 2))
      (def i (* i 2))
      (if (= (in plist i) key)
        (return result (+ i 1))))))

(defn plist/get [plist key]
  (when-let [idx (plist/index plist key)]
    (in plist idx)))

(defn plist/put [plist key val & rest]
  (when-let [idx (plist/index plist key)]
    (put plist idx val)))
