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
  (case (flake/info :desktop :type)
    "wayland" ($? echo ,text | wl-copy ,;(opts "-t" type) ,;(opts (if once "-o")))
    "x11"     ($? echo ,text | xclip -selection clipboard -i)))

(defn yank-file [file &named type once]
  (case (flake/info :desktop :type)
    "wayland" ($? wl-copy ,;(opts "-t" type) ,;(opts (if once "-o")) ,file)
    "x11"     ($? xclip -selection clipboard -i ,file)))

(defn paste []
  (case (flake/info :desktop :type)
    "wayland" ($<_ wl-paste)
    "x11"     ($? xclip -selection clipboard -o)))
