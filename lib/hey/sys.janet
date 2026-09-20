# lib/hey/sys.janet
#
# An API for the desktop session: sounds, notifications, and the clipboard.

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

(defn toast [type message &named details command category sound]
  (os/spawn ["dms" "ipc" "toast"
             (case* type
               :info  "infoWith"
               :error "errorWith"
               :warn  "warnWith")
             message
             (or details "")
             (or command "")
             (or category "")]
            :pd)
  (if sound (play-sound sound)))

(defn yank [text &named type once]
  ($? echo ,text | wl-copy ,;(opts "-t" type) ,;(opts (if once "-o"))))

(defn yank-file [file &named type once]
  ($? wl-copy ,;(opts "-t" type) ,;(opts (if once "-o")) ,file))

(defn paste []
  ($<_ wl-paste))
