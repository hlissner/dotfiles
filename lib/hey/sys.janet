# lib/hey/sys.janet
#
# An API for the desktop session: sounds, notifications, and the clipboard.

(import spork/json)
(import spork/path)
(use ./lib)
(use sh)

(defn play-sound [name &named volume]
  (when-let [file (path/sibling :file (path :assets "sounds" name)
                                ".ogg" ".wav" ".mp3")]
    (os/spawn ["play" "-q" ;(opts "-v" volume) file] :pd)))

(defn notify [message &named urgency title icon sound id]
  (os/spawn ["notify-send"
             ;(opts "-i" icon)
             ;(opts "-u" urgency)
             ;(opts "-r" id)
             ;(if title
                [title message]
                [message])]
            :pd)
  (if sound (play-sound sound)))

(defn toast [type message &named details category icon sound]
  (def payload @{:app_name "hey"
                 :summary message
                 :urgency (if (= type :error) "critical" "normal")})
  (when details (put payload :body details))
  (when category (put payload :category category))
  (when icon (put payload :icon icon))
  (os/spawn ["noctalia" "msg" "notification-show" (string (json/encode payload))]
            :pd)
  (if sound (play-sound sound)))

(defn yank [text &named type once]
  ($? echo ,text | wl-copy ,;(opts "-t" type) ,;(opts (if once "-o"))))

(defn yank-file [file &named type once]
  ($? wl-copy ,;(opts "-t" type) ,;(opts (if once "-o")) ,file))

(defn paste []
  ($<_ wl-paste))
