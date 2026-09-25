# Alternatives I considered:
# - spork/argparse: interface is too verbose and clumsy; doesn't allow short
#   options without an accompanying long option.
# - ianthehenry/cmd: much better, but doesn't parse options beyond the escape
#   argument (sigh). Also a little more verbose than I'd like.

(import spork/path)
(use ./lib)

(def- *argtypes* '[&opts &args &])

(defn- make-arg [arg]
  (let [spec (if (tuple? arg) arg [arg :string nil])]
    {:name (in spec 0)
     :default (get spec 2)}))

(defn- make-opt [name spec]
  (let [spec (if (tuple? spec) spec [spec])
        {false args true opts} (group-by |(string/has-prefix? "-" $0) spec)]
    {:name name
     :multiple (and args (index-of '* args) true)
     :options (map string opts)
     :arguments (if args (map make-arg (filter |(not= $0 '*) args)))}))

# TODO: Add opt validation
# TODO: Add arg validation
# TODO: Add arg default values
(defmacro cmdfn [spec & body]
  (let [argspec @[;spec]
        optbinds @[]
        optmap @{}
        argbinds @[]
        restbinds @[]]
    (var arg-type
         (or (if-let [b (get argspec 1)]
               (if (or (and (symbol? b)
                            (string/has-prefix? "-" b))
                       (tuple/type? b :brackets))
                 '&opts))
             '&args))
    (while (not (empty? argspec))
      (def arg (first (take! 1 argspec)))
      (if (index-of arg *argtypes*)
        (set arg-type arg)
        (case arg-type
          '&args (array/push argbinds (make-arg arg))
          '&opts (let [opt (make-opt arg (first (take! 1 argspec)))
                       idx (length optbinds)]
                   (array/push optbinds opt)
                   (each o (get opt :options) (put optmap o idx)))
          '& (if (>= (length restbinds) 2)
               (errorf "Too many & binds for %q" arg)
               (array/push restbinds arg)))))
    (with-syms [$rest $argv $all $argmap $optbinds $optmap]
      ~(fn [& args]
         (let [,$all args
               ,$argv @[;,$all]
               ,$rest @[]
               ,$argmap @{}
               ,$optmap ,optmap
               ,$optbinds (quote ,optbinds)]
           (while (not (empty? ,$argv))
             (def arg (first (,take! 1 ,$argv)))
             (cond (= arg "--")
                   (do (array/push ,$rest ;,$argv)
                       (break))

                   (and (string/has-prefix? "-" arg)
                        (> (length arg) 2)
                        (not (string/has-prefix? "--" arg)))
                   (array/insert
                    ,$argv 0 ;(map |(string "-" (string/from-bytes $0))
                                   (slice arg 1)))

                   (string/has-prefix? "-" arg)
                   (if-let [idx (get ,$optmap arg)
                            opt (get ,$optbinds idx)
                            val (if-let [args (get opt :arguments)]
                                  (let [len (length args)
                                        val (,take! len ,$argv)]
                                    (if (= len 1) (first val) val))
                                  arg)
                            bind (get opt :name)]
                     (put ,$argmap bind
                           (if (get opt :multiple)
                             [;(get ,$argmap bind []) ;(if (,atom? val) [val] val)]
                             val))
                     ,(if (> (length restbinds) 0)
                        ~(array/push ,$rest arg)
                        ~(,abort "Unrecognized option: %s" arg)))

                   (array/push ,$rest arg)))
           (let [[,;(map |($0 :name) argbinds) & ,(get restbinds 0 '_)] ,$rest
                 ,;(if-not (index-of (get restbinds 1) ['_ nil]) [(get restbinds 1) $all] [])]
             ,;(catseq [o :in optbinds]
                 (let [sym (get o :name)]
                   ~((def ,sym (or (get ,$argmap ',sym)
                                   ,(when-let [args (get o :arguments)
                                               vals (map |($0 :default) args)]
                                      (if (or (get o :multiple)
                                              (> (length args) 1))
                                        vals (first vals))))))))
             ,;body))))))

(defmacro defcmd-1 [kind name & rest]
  (def [name type] (if (tuple? name) name [name nil]))
  (def docs (if (string? (first rest)) (first rest)))
  (def rest (if docs (slice rest 1) rest))
  # Otherwise a typo in a struct dispatch and won't be noticed until runtime
  (unless (index-of type [nil :eval :exec :rules])
    (errorf "Unknown command kind for %s: %q" name type))
  ~(,(case kind :public 'def :private 'def- (errorf "Unknown type: %s" kind))
     ,name
     ,;(if docs [docs] [])
     ,(if type
        ~{:doc ,docs ,type (cmdfn ,;rest)}
        ~(cmdfn ,;rest))))

(defmacro defcmd- [name & rest]
  ~(defcmd-1 :private ,name ,;rest))

(defmacro defcmd [name & rest]
  ~(defcmd-1 :public ,name ,;rest))

(defmacro defmain [& rest]
  ~(defcmd-1 :public main ,;rest))
