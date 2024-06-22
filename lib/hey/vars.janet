(import spork/path)
(use ./lib)

(defn new [dir &opt raw?]
  (let [dir (path/abspath dir)]
    {:dir (fn [self & segments] (path/join dir ;segments))
     :file (fn [self key]
             (path/join dir ;(if (atom? key) [key] key)))
     :list (fn [self] (map keyword (os/dir dir)))
     :get (fn [self key &opt dflt]
            (let [file (:file self key)]
              (if (path/file? file)
                (with-umask 8r077
                  ((if raw? identity unmarshal) (slurp file)))
                dflt)))
     :set (fn [self key val]
            (let [file (:file self key)]
              (if (= val nil)
                (when (path/file? file)
                  (os/rm file)
                  key)
                (do (unless (path/directory? dir)
                      (os/execute ["mkdir" "-p" dir] :px))
                    (with-umask 8r077
                      (spit file ((if raw? identity marshal) val)))
                    val))))
     :clear (fn [self]
              (when (path/directory? dir)
                (each f (path/files-in dir)
                  (when (path/file? f)
                    (os/rm f)))))
     :cache (fn [self key valfn &opt reset?]
              (or (unless reset?
                    (:get self key))
                  (:set self key (valfn))))}))

(def global (new (path :data "vars.d")))
(def temp   (new (path :runtime "vars.d")))

(defn get [key &opt global?]
  (:get (if global? global temp) key))

(defn set [key val &opt global?]
  (:set (if global? global temp) key val))

(defn list [&opt global?]
  (:list (if global? global temp)))

(defmacro cached [vars key & body]
  ~(:cache ,vars ,key (fn [] ,;body)))
