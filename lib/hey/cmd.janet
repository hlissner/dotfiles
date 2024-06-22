# Alternatives I considered:
# - spork/argparse: interface is too verbose and clumsy; doesn't allow short
#   options without an accompanying long option.
# - ianthehenry/cmd: much better, but doesn't parse options beyond the escape
#   argument (sigh). Also a little more verbose than I'd like.

(import spork/path)
(use ./lib)

(def- *commands* @{})
(def- *argtypes* '[&opts &args &])

# TODO: Use me
# (defn- read-arg-value [spec val]
#   (cond (tuple? spec) (and (index-of val spec) val)
#         (= spec :boolean) (index-of val ["yes" "no" "on" "off" "0"" 1" "true" "false"])
#         (= spec :number) (scan-number (or val ""))
#         (= spec :path) (if (path/exists? val) val)
#         (= spec :file) (if (path/file? val) val)
#         (= spec :dir) (if (path/directory? val) val)
#         (= (type val) spec) val))

(defn- make-arg [arg]
  (let [spec (if (tuple? arg) arg [arg :string nil])]
    {:name (in spec 0)
     # :value (partial read-arg-value (get spec 1))
     :default |(get spec 2)}))

(defn- make-opt [name spec]
  (let [spec (if (tuple? spec) spec [spec])
        {false args true opts} (group-by |(string/has-prefix? "-" $) spec)]
    {:name name
     :multiple (and args (index-of '* args) true)
     :options (map string opts)
     :arguments (if args (map make-arg (filter |(not= $ '*) args)))}))

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
          '& (if (> (length restbinds) 2)
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
                    ,$argv 0 ;(map |(string "-" (string/from-bytes $))
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
                             [;(get ,$argmap bind []) ;(if (atom? val) [val] val)]
                             val))
                     ,(if (> (length restbinds) 0)
                        ~(array/push ,$rest arg)
                        ~(abort "Unrecognized option: %s" arg)))

                   (array/push ,$rest arg)))
           (let [[,;(map |($ :name) argbinds) & ,(get restbinds 0 '_)] ,$rest
                 ,;(if-not (index-of (get restbinds 1) ['_ nil]) [(get restbinds 1) $all] [])]
             ,;(catseq [o :in optbinds]
                 (let [sym (get o :name)]
                   ~((def ,sym (or (get ,$argmap ',sym)
                                   ,(when-let [args (get o :arguments)
                                               vals (map |(($ :default)) args)]
                                      (if (or (get o :multiple)
                                              (> (length args) 1))
                                        vals (first vals))))))))
             ,;body))))))

(defn cmd [name]
  (or (get *commands* name)
      (errorf "Unrecognized command: %s" name)))

(defn- defcmd* [name cmd file]
  (put *commands* name {:cmd cmd :file file}))

(defmacro defcmd-1 [type name argspec & body]
  ~(upscope
    (,(case type :public 'def :private 'def- (errorf "Unknown type: %s"))
      ,name (cmdfn [,;argspec] ,;body))
    ,(unless (= name 'main)
       ~(,defcmd* ',name ,name ,(path/abspath (dyn :current-file ""))))))

(defmacro defcmd- [name argspec & body]
  ~(defcmd-1 :private ,name [,;argspec] ,;body))

(defmacro defcmd [name argspec & body]
  ~(defcmd-1 :public ,name [,;argspec] ,;body))

(defmacro defmain [argspec & body]
  ~(defcmd-1 :public main [,;argspec] ,;body))
