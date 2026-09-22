#!/usr/bin/env janet
# Preview and copy an icon name.
#
# SYNOPSIS:
#   iconmenu [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Preview and select an icon (either from installed icon themes or from
#   tabler-icons; Noctalia's icon set). Copies the selected icon's name to
#   clipboard.
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
(import spork/sh :as fs)

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
  # The theme's store path makes for a good cache key
  (def dirs (theme-dirs))
  (def key (string (hash (string/join dirs ":"))))
  (or (unless reload? (:get *vars* key))
      (let [found (scan-icons dirs)]
        # A miss means the old key's entry is 3MB of dead weight. Sweep first.
        (:clear *vars*)
        (:set *vars* key found)
        found)))


(def- *tabler-dir* (path :data "tabler-icons"))

(def- *fg-peg* (peg! ~(some (+ (* "fg:" :s+ (<- (* "#" (some :h)))) 1))))

(defn- rofi-fg
  ``The colour rofi is about to draw text in. Noctalia rewrites this file on
  every theme change (modules/apps/rofi.nix wires up the template), so it's the
  one place the live palette exists as a hex I can hand to librsvg.``
  []
  (or (when-let [file (path/xdg :config "rofi" "themes" "colors.rasi")
                 text (ignore-errors (slurp file))]
        (first (peg/match *fg-peg* text)))
      "#ffffff"))

# Upstream draws every icon in `currentColor`, which librsvg (and rofi by
# extension) renders to black, which is horrible on dark palettes. So copy and
# fix them before presenting them!
(defn- recoloured
  ``*tabler-dir* in COLOR, cached under it. .``
  [color]
  (def dir (:dir *vars* (string "svg-" (string/slice color 1))))
  (unless (path/directory? dir)
    (def tmp (string dir ".new"))
    (fs/create-dirs (path/dirname tmp))
    # The palette may change, piling up in tmpfs ~2M at a time
    (each old (path/files-in (:dir *vars*))
      (when (string/has-prefix? "svg-" (path/basename old))
        (fs/rm old)))
    # -L because home-manager hands me a symlink into the store, and without it
    # cp copies the link, find declines to follow it, and sed silently edits
    # nothing at all. --no-preserve=mode because the store is 444.
    ($ cp -rLT --no-preserve=mode ,*tabler-dir* ,tmp)
    ($ find ,tmp -name "*.svg"
       -exec sed -i ,(string "s/currentColor/" color "/g") "{}" "+")
    (os/rename tmp dir))
  dir)

(defn- noctalia-icons
  ``{ NAME {:theme CATEGORY :codepoint "U+EC36" :file PATH} } for every glyph in
  Noctalia's icon font. Its name table is in the package's assets, on no XDG
  path and under no theme, so the only way in is backwards from the binary. No
  cache: it's one 500K json against the themes' 90k files.``
  [&opt _reload?]
  (def file (when-let [bin (path/find "noctalia")]
              (path/join (path/dirname (os/realpath bin)) ".."
                         "share/noctalia/assets/fonts/tabler.json")))
  (if-not (and file (path/file? file))
    {}
    (let [svgs (when (path/directory? *tabler-dir*) (recoloured (rofi-fg)))
          have (if svgs
                 (tabseq [f :in (os/dir svgs)] (path/no-ext f ".svg") true)
                 {})]
      (tabseq [[name entry] :pairs (json/decode (slurp file))]
        name {:theme (get entry "category")
              :codepoint (get entry "codepoint")
              :file (when (have name) (path/join svgs (string name ".svg")))}))))

(def- *icon* [["xdg" icons] ["tabler" noctalia-icons]])

(defn- catalogue
  ``Every icon from every set, flattened and tagged with where it came from.
  Sorted by name rather than grouped, so the two spellings of `battery` land
  next to each other instead of six thousand rows apart.``
  [&opt reload?]
  (def out @[])
  (each [set list-icons] *icon*
    (eachp [name entry] (list-icons reload?)
      (array/push out (merge entry {:name name :set set
                                    :sort (string name " " set)}))))
  (sorted-by |($0 :sort) out))

(defn- linked-to [entry]
  (let [link (get entry :link "")]
    (unless (empty? link)
      (path/no-ext (path/basename link)))))

(defn- label [entry]
  (fmt "<span alpha='50%%'><b>%s:</b></span> <b>%s</b> <span alpha='50%%' size='x-small'>%s(%s)</span>"
       (entry :set)
       (rofi/escape (entry :name))
       (if-let [target (linked-to entry)]
         (string "→ " (rofi/escape target) " ")
         "")
       (rofi/escape (entry :theme))))

(defn- select-icon [&opt reload?]
  (rofi/chain [r :theme "appmenu.rasi" :prompt "Icon"]
    (:add r "<b>Reload icons</b> →" :icon "reload" :data |(select-icon true))
    (:div r)
    (each entry (catalogue reload?)
      (:add r (label entry)
            # Noctalia's own dozen glyphs have no svg; they go without.
            ;(opts :icon (entry :file))
            :data [(entry :name) (or (entry :file) (entry :name))]))))

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  (if list?
    (each entry (catalogue reload?)
      (echof "%s\t%s\t%s\t%s%s" (entry :set) (entry :name) (entry :theme)
             (or (entry :file) (entry :codepoint))
             (if-let [target (linked-to entry)] (string "\t-> " target) "")))
    (when-let [sel (select-icon reload?)]
      # For a glyph that's its own name, which is what Noctalia wants anyway.
      (def [name icon] sel)
      (sys/yank name)
      (sys/notify name :title "Copied icon name" :icon icon))))
