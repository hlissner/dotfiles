# lib/hey/romm/retroid.janet
#
# For handling my Retroid devices (Android handhelds that run Windows games
# through GameNative) over Termux's sshd. GameNative has no API and keeps each
# game's Wine container -- so its saves -- under /data/data/app.gamenative,
# where only root can reach, so we can't. What it does expose:
# <SD>/GameNative/CustomGames, which it scans unasked, then
# Download/GameNative/<game>/, the one folder its Export Files / Import Files
# dialogs trade files with. Saves have an extra, manual step for
# importing/exporting them.

(use ../.)
(use sh)

(def games-subdir "GameNative/CustomGames")

(def mailbox-root "/storage/emulated/0/Download/GameNative")

(defn setup-hint [games-dir]
  (fmt "In GameNative: open the Library once to make it scan %s." games-dir))

(defn import-hint [folder]
  (fmt (string "In GameNative: %s > Import Files > the files in Download/GameNative/%s/, into the container folder "
               "they belong in (one import per folder); or Open container and copy them over from D: with its file manager.")
       folder folder))

(defn export-hint [folder]
  (fmt (string "In GameNative: %s > Export Files > tick the save files; they land in Download/GameNative/%s/. "
               "Or Open container and copy their folders onto D: (that same dir) with its file manager, structure kept.")
       folder folder))

(defn folder-name
  "Return a normalized folder name that appeases exFAT and GameNative."
  [name]
  (->> name
       (string/replace-all ": " " - ")
       (string/replace-all ":" " -")
       (peg/replace-all '(set "\"*/<>?\\|") "")
       (string)
       (string/trim)))

(defn android? [host]
  (def out @"")
  ($? ssh ,host "uname -o" > ,out > [stderr :null])
  (= (string/trim (string out)) "Android"))

(defn games-dir [host]
  (def out @"")
  (unless ($? ssh ,host
              "for d in /storage/*/; do case $d in /storage/emulated/|/storage/self/) ;; *) printf '%s\\n' \"${d%/}\";; esac; done"
              > ,out > [stderr :null])
    (abort "Couldn't list /storage on %s. Has Termux been given storage access (termux-setup-storage)?" host))
  (def roots (filter |(not (empty? $0)) (string/split "\n" (string out))))
  (case (length roots)
    0 (abort (string "No SD card in %s. GameNative moves games on internal storage into its private "
                     "data dir on first launch, where nothing can update them, so games only go on a card")
             host)
    1 (path/join (first roots) games-subdir)
    (abort "More than one external volume on %s: %s" host (string/join roots ", "))))

(defn mailbox-dir [folder]
  (path/join mailbox-root folder))

(defn games
  ``The game folders on HOST's SD card, as @[{:name :dir :exe :mbx}]: the folder
  name (the title GameNative shows), the first .exe within two levels, and
  whether anything is waiting in its mailbox.``
  [host]
  (def dir (games-dir host))
  (def out @"")
  (unless ($? ssh ,host
              ,(string "cd " (shell-quote dir) " 2>/dev/null || exit 0; "
                       "for g in */; do g=${g%/}; "
                       "e=$(find \"$g\" -maxdepth 2 -iname '*.exe' 2>/dev/null | head -n1); "
                       "[ -n \"$e\" ] || continue; "
                       "m=0; [ -n \"$(ls -A \"" mailbox-root "/$g\" 2>/dev/null)\" ] && m=1; "
                       "printf '%s\\t%s\\t%s\\n' \"$g\" \"$e\" \"$m\"; done")
              > ,out > [stderr :null])
    (abort "Couldn't list %s on %s" dir host))
  (seq [line :in (string/split "\n" (string out)) :unless (empty? line)
        :let [[name exe mbx] (string/split "\t" line)]]
    {:name name :dir (path/join dir name) :exe (path/join dir exe) :mbx (= mbx "1")}))

(defn find-game
  "The game in GAMES whose folder is NAME or NAME's folder-name, case insensitively."
  [games name]
  (def wanted (map string/ascii-lower [name (folder-name name)]))
  (find |(index-of (string/ascii-lower ($0 :name)) wanted) games))
