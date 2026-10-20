#!/usr/bin/env janet
# Select a Doom mod with Rofi and launch GZDoom with it.
#
# SYNOPSIS:
#   doommenu [-l|--list]
#
# DESCRIPTION:
#   Searches `modules.games.doom.wadsDir` for pk3/wad files (however deep).
#
# OPTIONS:
#   -l, --list
#     Print what the menu would show, one mod per line, and don't open it.

(use hey)
(import hey/rofi)

(def- *exts* [".pk3" ".wad" ".pk7" ".ipk3"])
(def- *theme* "appmenu.rasi")
(def- *icon* "gzdoom")

(def- *engine-files*
  {"gzdoom.pk3" true
   "game_support.pk3" true
   "game_widescreen_gfx.pk3" true
   "brightmaps.pk3" true
   "lights.pk3" true})

(defn- doom [key]
  (or (flake/info :doom key)
      (abort "modules.games.doom isn't enabled on this host")))

(defn- mod-file? [file]
  (def name (string/ascii-lower (path/basename file)))
  (and (not (*engine-files* name))
       (some |(string/has-suffix? $0 name) *exts*)))

(defn- walk [dir]
  (catseq [f :in (sorted (path/files-in dir))]
    (cond (path/directory? f) (walk f)
          (mod-file? f) [f]
          [])))

(defn- by-kind [files]
  (sort-by |(if (string/has-suffix? ".pk3" (string/ascii-lower $0)) 0 1) files))

(defn- mods []
  (def dir (doom :wadsDir))
  (unless (path/directory? dir)
    (abort "No such directory: %s" dir))
  (seq [f :in (sorted (path/files-in dir))
        :let [files (if (path/directory? f) (by-kind (walk f)) (if (mod-file? f) [f] []))]
        :unless (empty? files)]
    {:name (path/basename f) :files files}))

(defn- launch [& files]
  (echof "Launching gzdoom with %s"
         (if (empty? files) "no mods" (string/join (map path/basename files) " ")))
  (os/spawn ["gzdoom" "-iwad" (doom :iwad) ;(if (empty? files) [] ["-file" ;files])]
            :pd))

(defn- label [mod]
  (fmt "<b>%s</b> <span alpha='50%%' size='x-small'>%s</span>"
       (rofi/escape (mod :name))
       (rofi/escape (string/join (map path/basename (mod :files)) " "))))

(defmain [_ &opts list? [-l --list]]
  (def all (mods))
  (if list?
    (each m all (echof "%s\t%s" (m :name) (string/join (m :files) " ")))
    (let [pick (rofi/with [r :prompt "Doom"
                             :icon *icon*
                             :placeholder "Search mods..."
                             :theme *theme*]
                 (:add r "<b>Vanilla</b>" :icon *icon* :data :vanilla)
                 (:div r)
                 (each m all
                   (:add r (label m) :icon "package-x-generic" :data m)))]
      # Rofi hands back the raw query when nothing was selected.
      (cond (= pick :vanilla) (launch)
            (dictionary? pick) (launch ;(pick :files))
            (abort "Aborted")))))
