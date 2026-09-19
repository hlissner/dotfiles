(import spork/path)
(import spork/sh)
(use ./lib)

(defn- key->file
  ``Sanitized DIR/KEY, to prevent escaping.``
  [dir key]
  (def name (string key))
  (if (or (empty? name)
          (= name ".")
          (= name "..")
          (string/find "/" name)
          (string/find `\` name))
    (errorf "Invalid var name: %q" name)
    (path/join dir name)))

(defn new [dir &opt raw?]
  (let [dir (path/abspath dir)]
    {:dir (fn [self & segments] (path/join dir ;segments))
     :file (fn [self key] (key->file dir key))
     # Nothing has been set yet is an empty store, not an error.
     :list (fn [self] (map keyword (or (ignore-errors (os/dir dir)) [])))
     :get (fn [self key &opt dflt]
            (let [file (:file self key)]
              (if (path/file? file)
                ((if raw? identity unmarshal) (slurp file))
                dflt)))
     :set (fn [self key val]
            (let [file (:file self key)]
              (if (nil? val)
                (when (path/file? file)
                  (os/rm file))
                (do (unless (path/directory? dir)
                      (sh/create-dirs dir))
                    (with-umask 8r077
                      (spit file ((if raw? identity marshal) val)))))
              key))
     :clear (fn [self]
              (when (path/directory? dir)
                (each f (path/files-in dir)
                  (when (path/file? f)
                    (os/rm f)))))
     :cache (fn [self key valfn &opt reset?]
              (let [cached (unless reset? (:get self key))]
                (if (nil? cached)
                  (let [val (valfn)]
                    (:set self key val)
                    val)
                  cached)))}))

# Deferred because jpm quickbin compiles top-level values AOT with hey (see
# modules/hey.nix).
(def global (delay (new (path :data "vars.d"))))
(def temp   (delay (new (path :runtime "vars.d"))))

(defn get [key &opt global?]
  (:get (if global? (global) (temp)) key))

(defn set [key val &opt global?]
  (:set (if global? (global) (temp)) key val))

(defn list [&opt global?]
  (:list (if global? (global) (temp))))

(defmacro cached [vars key & body]
  ~(:cache ,vars ,key (fn [] ,;body)))
