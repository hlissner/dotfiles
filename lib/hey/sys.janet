(import spork/path)
(use ./lib)
(use sh)

(defn play-sound [name &named volume]
  (when-let [file (path/sibling :file (path :theme "sounds" name)
                                ".ogg" ".wav" ".mp3")]
    (os/spawn ["play" "-q" ;(opts "-v" volume) file] :pd)))

(defn notify [message &named urgency title icon sound]
  (os/spawn ["notify-send"
             ;(opts "-i" icon)
             ;(opts "-u" urgency)
             ;(if title
                [title message]
                [message])]
            :pd)
  (if sound (play-sound sound)))

(defn yank [text &named type once]
  ($? echo ,text | wl-copy ,;(opts "-t" type) ,;(opts (if once "-o"))))

(defn yank-file [file &named type once]
  ($? wl-copy ,;(opts "-t" type) ,;(opts (if once "-o")) ,file))

(defn paste []
  ($<_ wl-paste))
