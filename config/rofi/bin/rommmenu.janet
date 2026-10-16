#!/usr/bin/env janet
# Search games on a Romm instance via Rofi.
#
# SYNOPSIS:
#   rommmenu [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Searches https://romm.home.lissner.net. Selecting one opens its page in the
#   browser. Can be filtered by platform, collection, or playing status.
#   Consults rbw for secrets.
#
# OPTIONS:
#   -l, --list
#     Print what the menu would show and don't open it.
#   -r, --reload
#     Refetch the library and any covers it's missing, rather than trust the
#     cache.

(use hey)
(use sh)
(import hey/rofi)
(import hey/rbw)
(import hey/romm)
(import hey/vars)
(import spork/sh :as fs)

(def- *vars* (vars/new (:dir (vars/global) :rofi :rommmenu)))
(def- *covers* (:dir *vars* :covers))
(def- *logos* (:dir *vars* :platforms))
(def- *fallback-icon* "input-gaming-symbolic")
(def- *theme* "appmenu.rasi")

(def- *statuses*
  [["incomplete"    "Incomplete"    "media-playback-start-symbolic"]
   ["finished"      "Finished"      "emblem-ok-symbolic"]
   ["completed_100" "Completed"     "starred-symbolic"]
   ["retired"       "Retired"       "media-playback-stop-symbolic"]
   ["never_playing" "Never Playing" "window-close-symbolic"]])

(defn- val [v]
  (unless (or (nil? v) (= v :null) (= v "")) v))

(defn- asset-url [path]
  # RomM dates its cover paths (?ts=YYYY-MM-DD HH:MM:SS), space and all.
  (string (romm/url-base) (string/replace-all " " "%20" path)))

(defn- cover-file [key cover]
  (path/join *covers* (fmt "%s-%d.png" (string key) (hash cover))))

(defn- logo-file [slug]
  (path/join *logos* (string slug ".svg")))

(defn- fetch-roms []
  # 10000 is the API's ceiling, and more than the library holds; the loop is
  # for the day it isn't. The page is ~80M of metadata I don't want, so keep
  # only what the menu shows and let the rest go.
  (def limit 10000)
  (def roms @[])
  (forever
    (def page (romm/api/get "/api/roms" {:limit limit :offset (length roms) :order_by "name"}))
    (def items (get page :items []))
    (array/concat roms items)
    (when (< (length items) limit) (break)))
  (seq [r :in roms
        :let [cover (val (r :path_cover_small))
              slug (val (r :platform_slug))]]
    {:id (r :id)
     :file (r :fs_name)
     :year (when-let [ms (val (get-in r [:metadatum :first_release_date]))]
             (get (os/date (div ms 1000)) :year))
     :platform (or (val (r :platform_display_name)) slug "?")
     :slug slug
     :status (val (get-in r [:rom_user :status]))
     :cover (when cover (cover-file (r :id) cover))
     :cover-url (when cover (asset-url cover))}))

(defn- fetch-collections []
  # Excludes smart and virtual collections
  (def cols (romm/api/get "/api/collections"))
  (seq [c :in (if (dictionary? cols) (cols :items) cols)
        :let [cover (or (val (c :path_cover_small))
                        (first (get c :path_covers_small [])))]]
    {:id (c :id)
     :name (c :name)
     :roms (tabseq [id :in (get c :rom_ids [])] id true)
     :cover (when cover (cover-file (string "c" (c :id)) cover))
     :cover-url (when cover (asset-url cover))}))

(defn- sync-icons!
  ``One parallel curl for every cover and platform logo in ITEMS that isn't on
  disk, then sweep the covers nothing names any more. Everything fetched goes
  through magick: "small" covers run to 600px and half a meg, and half are webp,
  which rofi's gdk-pixbuf has no loader for.``
  [items]
  (fs/create-dirs *covers*)
  (fs/create-dirs *logos*)
  (def wanted @{})
  (def fetch @[])
  (def covers @[])
  (each i items
    (when-let [file (i :cover)]
      (put wanted file true)
      (unless (path/file? file)
        # Downloaded under the server's extension, for mogrify's sake.
        (def tmp (if (string/find ".webp" (i :cover-url))
                   (string (path/no-ext file ".png") ".webp")
                   file))
        (array/push covers tmp)
        (array/push fetch [(i :cover-url) tmp]))))
  (each slug (distinct (filter truthy? (map |($0 :slug) items)))
    (unless (path/file? (logo-file slug))
      (array/push fetch [(asset-url (fmt "/assets/platforms/%s.svg" slug)) (logo-file slug)])))
  (each old (path/files-in *covers*)
    (unless (wanted old) (os/rm old)))
  (unless (empty? fetch)
    (def cfg (path/join *covers* "curl.cfg"))
    (spit cfg (string "parallel\nfail\nsilent\nshow-error\n"
                      (string/join (seq [[url out] :in fetch]
                                     (fmt "url = %q\noutput = %q\n" url out))
                                   "")))
    # Covers RomM never fetched 404; -f leaves no file and rofi gets the logo.
    (defer (os/rm cfg)
      (run curl -K ,cfg))
    (def got (filter path/file? covers))
    (unless (empty? got)
      ($ magick mogrify -format png -thumbnail x96 ,;got)
      (each f got
        (unless (string/has-suffix? ".png" f) (os/rm f))))))

(defn- library [&opt reload?]
  (:cache *vars* :library
    (fn []
      (unless (or (rbw/unlocked?) (rbw/unlock))
        (abort "Vault is locked"))
      (let [lib {:roms (fetch-roms) :collections (fetch-collections)}]
        (sync-icons! [;(lib :roms) ;(lib :collections)])
        lib))
    reload?))

(defn- roms [] ((library) :roms))
(defn- collections [] ((library) :collections))

(defn- cover [item]
  (when-let [c (item :cover)] (when (path/file? c) c)))

(defn- logo [slug]
  (when slug (when (path/file? (logo-file slug)) (logo-file slug))))

(defn- icon [rom]
  (or (cover rom) (logo (rom :slug)) *fallback-icon*))

# The slug is what the NAS dirs are named after, and fits; the display name
# runs to "Super Nintendo Entertainment System".
(defn- platform [rom]
  (or (rom :slug) (rom :platform)))

(defn- label [rom]
  (fmt "<b>%s</b>%s <span alpha='50%%' size='x-small'>(%s)</span>"
       (rofi/escape (rom :file))
       (if-let [y (rom :year)] (fmt " [%d]" y) "")
       (rofi/escape (platform rom))))

(defn- open-url [url]
  (echof "Opening: %s" url)
  (os/spawn ["xdg-open" url] :pd))

(defn- open-rom [rom]
  (open-url (fmt "%s/rom/%d" (romm/url-base) (rom :id))))


## Screens

(defn- enter [screen & args]
  (fn [] (let [r (screen ;args)] (if (= r :back) :restart r))))

(defn- games-screen [prompt roms &opt prompt-icon]
  (rofi/chain [r :prompt prompt
                 :icon (or prompt-icon *fallback-icon*)
                 :placeholder "Search games..."
                 :theme *theme*]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (each rom roms
      (:add r (label rom) :icon (icon rom) :data rom))))

(defn- browse-screen
  ``A screen of ROWS, [name icon roms &opt label], each a games screen.``
  [prompt rows]
  (rofi/chain [r :prompt prompt
                 :icon *fallback-icon*
                 :placeholder (fmt "Search %s..." (string/ascii-lower prompt))
                 :theme *theme*]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (each [name icon roms label] rows
      (:add r (or label (rofi/escape name))
            :icon (or icon *fallback-icon*)
            :data (enter games-screen name roms icon)))))

(defn- platforms-screen []
  (def groups (group-by |($0 :platform) (roms)))
  (browse-screen "Platforms"
    (seq [name :in (sorted (keys groups)) :let [rs (groups name)]]
      [name (logo ((first rs) :slug)) rs
       (fmt "%s <span alpha='50%%' size='x-small'>(%d)</span>"
            (rofi/escape name) (length rs))])))

(defn- collections-screen []
  (browse-screen "Collections"
    (seq [c :in (collections)]
      [(c :name) (or (cover c) "folder-symbolic")
       (filter |((c :roms) ($0 :id)) (roms))])))

(defn- statuses-screen []
  (browse-screen "Statuses"
    (seq [[status name icon] :in *statuses*]
      [name icon (filter |(= ($0 :status) status) (roms))])))

(defn- select-rom []
  (rofi/chain [r :prompt "Games"
                 :icon *fallback-icon*
                 :placeholder "Search games..."
                 :theme *theme*]
    (:add r "<b>Reload</b>" :icon "view-refresh-symbolic" :data (fn [] (library true) :restart))
    (:add r "<b>Open in Browser</b> ->" :icon "web-browser-symbolic" :data (fn [] (open-url (romm/url-base)) :done))
    (:add r "<b>By platform</b> ->" :icon "view-list-symbolic" :data (enter platforms-screen))
    (:add r "<b>By collection</b> ->" :icon "folder-symbolic" :data (enter collections-screen))
    (:add r "<b>By status</b> ->" :icon "emblem-ok-symbolic" :data (enter statuses-screen))
    (:div r)
    (each rom (roms)
      (:add r (label rom) :icon (icon rom) :data rom))))

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  # Fetch (or refetch) up front. An error inside rofi's writer fiber is an
  # empty menu, not a message; out here it's an abort I can read.
  (library reload?)
  (if list?
    (each rom (roms)
      (echof "%s\t%s\t%s\t%s" (rom :file) (string (or (rom :year) "-")) (platform rom) (icon rom)))
    # Anything that isn't a ROM already did its thing on the way out.
    (let [pick (select-rom)]
      (when (dictionary? pick) (open-rom pick)))))
