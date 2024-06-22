# lib/hey/rofi.janet
#
# An API for interacting with Rofi.

(use ./.)
(import spork/htmlgen)
(import spork/base64)

(def escape htmlgen/escape)
(def encode base64/encode)
(def decode base64/decode)

(def config @{})

(defn exit []
  (os/execute ["pkill" "rofi"] :p))

(defn instance [& plist]
  (def cfg (merge config (struct ;plist)))
  (with-envvars ["ROFI_PLACEHOLDER" (if-let [ph (get cfg :placeholder)]
                                      (fmt "\"%s\"" ph))]
    # (each binds (get cfg :bind)
    #   )
    (os/spawn ["rofi" "-dmenu" "-markup-rows"
               ;(opts "-i" (not (get cfg :case-sensitive)))
               ;(opts "-p" (get cfg :prompt))
               ;(opts "-mesg" (get cfg :message))
               ;(opts "-theme" (get cfg :theme))
               ;(opts "-theme-str" (if (get cfg :icon) (fmt `icon{filename:"%s";}` (get cfg :icon))))
               ;(opts (if (get cfg :password) "-password"))
               ;(opts (if (get cfg :multiple) "-multi-select"))]
              :pd {:in :pipe :out :pipe})))

(defn- prep-line [line plist]
  (string line "\0"
          (string/join
           (catseq [[k v] :in (partition 2 plist)]
             (if (= k :data)
               [] [(string k "\x1f" (if (atom? v) v (encode (marshal v))))]))
           "\x1f")
          "\n"))

(defn call [f & plist]
  (with [rofi (instance ;plist)]
    (let [items @{}
          binds @{}
          fib (ev/go
               (coro
                (try (defer (ev/close (rofi :in))
                       (f {:in (rofi :in)
                           :out (rofi :out)
                           :add (fn [self line & plist]
                                  (when-let [idx (index-of :data plist)]
                                    (put items line (get plist (+ idx 1))))
                                  (ev/write (self :in) (prep-line line plist) 3))
                           :div (fn [self & plist]
                                  (ev/write
                                   (self :in)
                                   (prep-line "<span alpha='30%%'>------------------------------------------------------------</span>"
                                              [:nonselectable true ;plist])))
                           :on-code (fn [self code action] (put binds code action))
                           :sleep (fn [self n] (ev/sleep n))
                           # :set (fn [self & plist]
                           #        (ev/write (self :in) (prep-line "" plist)))
                          }))
                     ([err fib]
                      # in case of premature abort
                      (or (= err "stream is closed")
                          (= err "stream err")
                          (= err :exit)
                          (= (first err) :exit)
                          (propagate err fib))))))
          buf @""]
      (defer (ev/cancel fib :exit)
        (when (ev/read (rofi :out) :all buf)
          (os/proc-wait rofi)
          (let [str (string/chomp buf)
                val (if (has-key? items str) (get items str) str)]
            (if-let [f (get binds (get rofi :return-code))]
              (f val) val)))))))

(defn pick [items & plist]
  (call (fn [rofi]
          (each i items
            (:add rofi ;(if (atom? i)
                          [(string i)]
                          [;i ;(if (get i :data) [] [:data i])]))))
        (struct ;plist)))

(defn read [& plist]
  (call (fn [_]) ;plist))

(defn prompt [question &named yes no]
  (call (fn [rofi]
          (:add rofi (or yes "Yes") :data true)
          (:add rofi (or no  "No")  :data false))
        :message question
        :theme "modal.rasi"))

(defmacro with ([sym & plist] & body)
  ~(,call (fn [,sym] ,;body) ,;plist))

(defn error [message & args]
  (os/spawn ["rofi" "-markup" "-e"
             (string "<b>Uncaught error:</b>\n\n"
                     (escape (fmt message ;args)))]
            :pd)
  (errorf message ;args))

(defmacro chain [[sym & plist] & body]
  ~(let [init (fn [] (,call (fn [,sym] ,;body) ,;plist))]
     (var n init)
     (while (set n (n))
       (cond (= n :restart) (set n init)
             (nil? n) (abort "Aborted")
             (not (function? n)) (break)))
     n))
