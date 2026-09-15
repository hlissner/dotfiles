#!/usr/bin/env janet
# Preview and copy an icon name.
#
# SYNOPSIS:
#   iconmenu [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Every icon in every installed theme, drawn as itself. Pick one and its name
#   lands on the clipboard, which is the only part I ever actually want.
#
#   The fine print says which theme I'm looking at and, for the three icons in
#   five that are symlinks, what they point at.
#
#   Icons are handed to rofi by absolute path, not by name: half these themes
#   aren't the one rofi is themed with, and it would refuse to look in them.
#
#   REQUIRES: rofi, find, wl-copy
#
# OPTIONS:
#   -l, --list
#     Print what the menu would show and don't open it.
#   -r, --reload
#     Rescan the themes rather than trust the cache.

(use hey)
(use hey/cmd)
(use sh)
(import hey/sys)
(import hey/rofi)
(import hey/vars)

(defn- icon-roots []
  # Where the icon theme spec says to look, minus the ones I don't have.
  (filter path/directory?
          (distinct
           [(path/join (os/getenv "HOME") ".icons")
            (path/xdg :data "icons")
            ;(map |(path/join $0 "icons")
                  (string/split ":" (or (os/getenv "XDG_DATA_DIRS") "")))])))

(defn- theme-dirs []
  # Every theme here is a symlink into the store, and find won't descend one
  # unless I hand it the resolved path. Sorted because os/dir hands me readdir
  # order, and I'd rather ties below (and the cache key) not hinge on that.
  (distinct
   (seq [root :in (icon-roots)
         name :in (sorted (or (ignore-errors (os/dir root)) []))
         :let [dir (path/join root name)]
         :when (path/directory? dir)]
     (os/realpath dir))))

(def- *size-peg* (peg! ~(some (+ (* (<- :d+) "x" :d+) 1))))

(defn- resolution
  ``How big FILE's copy of an icon is, for picking between the dozen sizes every
  theme ships. A 16px preview is a smudge, so scalable wins outright.``
  [file]
  (if (string/find "/scalable/" file)
    math/inf
    (scan-number (or (first (peg/match *size-peg* file)) "0"))))

(defn- scan-icons
  ``{ NAME {:file PATH :theme THEME :link TARGET} } for every icon in DIRS. One
  find beats walking 90k files from janet.``
  [dirs]
  (def out ($<_ find ,;dirs
                "(" -name "*.svg" -o -name "*.png" -o -name "*.xpm" ")"
                # %H is the theme dir I handed find; %l is the symlink's target,
                # and empty for a real file.
                -printf "%H\t%p\t%l\n"))
  (def best @{})
  (loop [line :in (string/split "\n" out)
         :unless (empty? line)
         :let [[root file link] (string/split "\t" line)
               name (path/no-ext (path/basename file))
               size (resolution file)]
         # Biggest copy wins; ties go to the first theme dir, so anything I
         # dropped in ~/.icons myself outranks the system's.
         :when (> size (get-in best [name :size] -1))]
    (put best name {:file file
                    :link link
                    :size size
                    :theme (path/basename root)}))
  best)

# Lives in $XDG_RUNTIME_DIR, so a reboot rescans whether I ask it to or not.
(def- *vars* (vars/new (:dir (vars/temp) :rofi :iconmenu)))

(defn- icons [&opt reload?]
  # The themes ARE the cache key. They're store paths, so a rebuild or a GC
  # moves them and every path I cached points at nothing; comparing the list
  # costs nothing, where stat'ing 90k files would.
  (def dirs (theme-dirs))
  (def key (string (hash (string/join dirs ":"))))
  (or (unless reload? (:get *vars* key))
      # A miss means the old key's entry is 3MB of dead weight. Sweep first.
      (do (:clear *vars*)
          (:set *vars* key (scan-icons dirs)))))

(defn- linked-to [entry]
  (let [link (get entry :link "")]
    (unless (empty? link)
      (path/no-ext (path/basename link)))))

(defn- label
  ``NAME in bold, then in fine print what it points at (if anything) and whose
  theme I'm looking at.``
  [name entry]
  (fmt "<b>%s</b> <span alpha='50%%' size='x-small'>%s(%s)</span>"
       (rofi/escape name)
       (if-let [target (linked-to entry)]
         (string "→ " (rofi/escape target) " ")
         "")
       (rofi/escape (entry :theme))))

(defn- select-icon [&opt reload?]
  (rofi/chain [r :theme "appmenu.rasi" :prompt "Icon"]
    (:add r "<b>Reload icons</b> →" :icon "reload" :data |(select-icon true))
    (:div r)
    (each [name entry] (sorted (pairs (icons reload?)))
      (:add r (label name entry)
            :icon (entry :file)
            :data [name (entry :file)]))))

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  (if list?
    (each [name entry] (sorted (pairs (icons reload?)))
      (echof "%s\t%s\t%s%s" name (entry :theme) (entry :file)
             (if-let [target (linked-to entry)] (string "\t-> " target) "")))
    (when-let [sel (select-icon reload?)]
      (def [name file] sel)
      (sys/yank name)
      (sys/notify name :title "Copied icon name" :icon file))))
