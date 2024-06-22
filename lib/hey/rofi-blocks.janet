# /lib/hey/rofi-blocks.janet
#
# An API for interacting with rofi-blocks.

(use ./.)
(import spork/htmlgen)
(import spork/base64)

(def escape htmlgen/escape)
(def encode base64/encode)
(def decode base64/decode)

(def config @{})

(defn exit []
  (os/execute ["pkill" "rofi"] :p))

(defn- as-css [val]
  (when val
    (case (type val)
      :number (fmt "%d" val)
      (fmt "\"%s\"" (string val)))))


(defn to-json [obj]
  (json/encode obj))

(defn- to-entry [line plist]
  (string line "\0"
          (string/join
           (catseq [[k v] :in (partition 2 plist)]
             (if (= k :data)
               [] [(string k "\x1f" (if (atom? v) v (encode (marshal v))))]))
           "\x1f")
          "\n"))

(defn make-line [&named text urgent highlight markup nonselectable icon data]
  {:text text
   :urgent urgent
   :highlight highlight
   :markup markup
   :nonselectable nonselectable
   :icon icon
   :data data})

(defn make-state [&named message overlay prompt input active-entry lines]
  {:message nil
   :overlay nil
   :prompt nil
   :input nil
   :active-entry nil
   :lines @[]})

(def sessions @[])

(defn make-session [& plist]
  (unless (empty? sessions)
    (exit))
  (def cfg (merge config (struct ;plist)))
  (with-envvars ["ROFI_PLACEHOLDER" (as-css (get cfg :placeholder))]
    (let [sess @{:process
                 (os/spawn ["rofi" "-modi" "blocks" "-show" "blocks" "-markup"
                            ;(opts "-i" (not (get cfg :case-sensitive)))
                            ;(opts "-theme" (get cfg :theme))
                            ;(opts "-theme-str" (if (get cfg :icon) (fmt `icon{filename:"%s";}` (get cfg :icon))))])
                 :changed false
                 :alive? (fn [self] )
                 :input-action :filter
                 :state (make-state)
                 :old-state @{}}]
      (array/push sessions sess)
      sess)))

(defn start [f & plist]
  (let [sessions @[]
        session (make-session ;plist)]
    )
  )

(defn call [f & plist]
  (with [rofi (instance ;plist)]
    (var items @[])
    (let [binds @{}
          fib (ev/go
               (coro
                (try (defer (ev/close (rofi :in))
                       (f {:in (rofi :in)
                           :out (rofi :out)
                           :div (fn [self & plist]
                                  (ev/write
                                   (self :in)
                                   (prep-line "<span alpha='30%%'>------------------------------------------------------------</span>"
                                              [:nonselectable true ;plist])))
                           :on-code (fn [self code action] (put binds code action))
                           :sleep (fn [self n] (ev/sleep n))
                           :set (fn [self & plist]
                                  (let [data (table ;plist)]
                                    (when-let [lines (get data :lines)]
                                      (set items lines))
                                    (ev/write (self :in) (to-json data))))
                           :add (fn [self line & plist]
                                  (let [idx (length items)
                                        data (table :text line ;plist)]
                                  (array/push items (struct ;(kvs data)))
                                  (put data :data idx)
                                  (ev/write (self :in) (to-json data))))
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
