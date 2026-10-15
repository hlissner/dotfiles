#!/usr/bin/env janet
# Find a game in RomM via Rofi, and open its page.
#
# SYNOPSIS:
#   rommmenu [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Every ROM RomM knows about, with its cover for an icon (the platform's logo
#   when it hasn't got one). Selecting one opens its page in the browser.
#
#   The library is cached in $XDG_DATA_HOME, so only the first run (and
#   Reload) talks to the server, or needs the vault.
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
(import hey/romm)
(import hey/vars)
(import spork/sh :as fs)

(def- *vars* (vars/new (:dir (vars/global) :rofi :rommmenu)))
(def- *covers* (:dir *vars* :covers))
(def- *logos* (:dir *vars* :platforms))
(def- *fallback-icon* "input-gaming-symbolic")

(defn- val [v]
  (unless (or (nil? v) (= v :null) (= v "")) v))

(defn- asset-url [path]
  # RomM dates its cover paths (?ts=YYYY-MM-DD HH:MM:SS), space and all.
  (string (romm/url-base) (string/replace-all " " "%20" path)))

(defn- cover-file
  ``Where ROM's cover lands. The ts in the path is part of the name, so a
  rescanned cover is a new file and the old one is garbage, not a stale hit.``
  [id cover]
  (path/join *covers* (fmt "%d-%d.png" id (hash cover))))

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
     :cover (when cover (cover-file (r :id) cover))
     :cover-url (when cover (asset-url cover))}))

(defn- sync-icons!
  ``One parallel curl for every cover and platform logo in ROMS that isn't on
  disk, then sweep the covers nothing names any more. Everything fetched goes
  through magick: "small" covers run to 600px and half a meg, and half are
  webp, which rofi's gdk-pixbuf has no loader for.``
  [roms]
  (fs/create-dirs *covers*)
  (fs/create-dirs *logos*)
  (def wanted @{})
  (def fetch @[])
  (def covers @[])
  (each r roms
    (when-let [file (r :cover)]
      (put wanted file true)
      (unless (path/file? file)
        # Downloaded under the server's extension, for mogrify's sake.
        (def tmp (if (string/find ".webp" (r :cover-url))
                   (string (path/no-ext file ".png") ".webp")
                   file))
        (array/push covers tmp)
        (array/push fetch [(r :cover-url) tmp]))))
  (each slug (distinct (filter truthy? (map |($0 :slug) roms)))
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

(defn- roms [&opt reload?]
  (:cache *vars* :roms
    (fn [] (let [rs (fetch-roms)] (sync-icons! rs) rs))
    reload?))

(defn- icon [rom]
  (or (when-let [c (rom :cover)] (when (path/file? c) c))
      (when-let [s (rom :slug)] (when (path/file? (logo-file s)) (logo-file s)))
      *fallback-icon*))

# The slug is what the NAS dirs are named after, and fits; the display name
# runs to "Super Nintendo Entertainment System".
(defn- platform [rom]
  (or (rom :slug) (rom :platform)))

(defn- label [rom]
  (fmt "<b>%s</b>%s <span alpha='50%%' size='x-small'>(%s)</span>"
       (rofi/escape (rom :file))
       (if-let [y (rom :year)] (fmt " [%d]" y) "")
       (rofi/escape (platform rom))))

(defn- open-rom [rom]
  (def url (fmt "%s/rom/%d" (romm/url-base) (rom :id)))
  (echof "Opening: %s" url)
  (os/spawn ["xdg-open" url] :pd))

(defn- select-rom []
  (rofi/chain [r :prompt "Games"
                 :icon *fallback-icon*
                 :placeholder "Search games..."
                 :theme "appmenu.rasi"]
    (:add r "<b>Reload</b>" :icon "view-refresh-symbolic" :data (fn [] (roms true) :restart))
    (:div r)
    (each rom (roms)
      (:add r (label rom) :icon (icon rom) :data rom))))

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  (when reload? (roms true))
  (if list?
    (each rom (roms)
      (echof "%s\t%s\t%s\t%s" (rom :file) (string (or (rom :year) "-")) (platform rom) (icon rom)))
    (when-let [rom (select-rom)]
      (open-rom rom))))
