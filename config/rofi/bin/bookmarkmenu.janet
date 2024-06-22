#!/usr/bin/env janet
# Open a Firefox bookmark via Rofi.
#
# SYNOPSIS:
#   bookmarkmenu [-r|--reload] [--profile PROFILE]

(use hey)
(use hey/cmd)
(import hey/rofi)
(import hey/vars)
(import sqlite3 :as sql)

(defn- profile-dir [&opt profile]
  (some (fn [dir]
          (def dir (path/join dir ".mozilla" "firefox"))
          (when (path/directory? dir)
            (def file (path/join dir "profiles.ini"))
            (when (path/file? file)
              (var profile profile)
              (unless profile
                (with [f (file/open file :r)]
                  (each l (file/lines f)
                    (when (string/has-prefix? "Path=" l)
                      (set profile (get (string/split "=" l 0 2) 1))
                      (break)))))
              (when path
                (path/join dir (string/chomp profile))))))
        (filter truthy? [(os/getenv "XDG_FAKE_HOME") (os/getenv "HOME")])))

(defn- db [profile file &opt reload?]
  # Copy the sqlite database to get around locks. Fortunately, FF's dbs are
  # small enough that this is inexpensive. A more ideal alternative would be to
  # open the DB connection in immutable mode, but the janet sqlite3 lib doesn't
  # give us a way to do so.
  (def profile (profile-dir profile))
  (def copy (path :runtime (fmt "browsermenu.%s-%s"
                                (path/basename profile)
                                (path/basename file))))
  (try (do
         (when (or reload? (not (path/file? copy)))
           ($? cp -f ,;(opts (debug?) "-v") ,(path/join profile file) ,copy)
           ($? chmod ,;(opts (debug?) "-v") 400 ,copy))
         (sql/open copy))
       ([err fib]
        (ignore-errors (os/rm copy))
        (propagate err fib))))

(def- *vars*  (vars/new (:dir vars/global :rofi :bookmarkmenu)))
(def- *icons* (vars/new (:dir *vars* :icons) true))

(defn- icon-file [data]
  (when data
    (let [key (string (hash data))]
      (:cache *icons* key |data)
      (:file *icons* key))))

(defn bookmarks [profile &opt reload?]
  (:cache *vars* :bookmarks
    |(with [dbbk (db profile "places.sqlite" reload?)]
       (let [res (sql/eval dbbk `
                   SELECT mb.id, mb.parent, mb.type, mb.title, mp.url FROM moz_bookmarks mb
                   LEFT JOIN moz_places mp ON mb.fk = mp.id
                   WHERE mb.type = 1 AND mb.title<>''
                   ORDER BY mp.frecency DESC
                 `)]
         (with [dbfav (db profile "favicons.sqlite" reload?)]
           (eachp [i v] res
             (def {:title title :parent parent :type type :url url} v)
             (when url
               (def favs (sql/eval dbfav (fmt `
                           SELECT max(ic.data) AS data FROM moz_pages_w_icons pg, moz_icons_to_pages rel, moz_icons ic
                           WHERE pg.id = rel.page_id AND ic.id=rel.icon_id AND (pg.page_url="%s" OR pg.page_url LIKE '%%%s%%')
                           LIMIT 1
                         ` url (first (string/split "/" (peg/replace '(* "http" (? "s") "://" (? "www.")) "" url) 0 2)))))
               (unless (empty? favs)
                 (put res i (struct ;(kvs v) :favicon (icon-file (get (first favs) :data))))))))
         res))
    reload?))

(defn- open-url [result]
  (when result
    (echof "Opening: %s" (get result :url))
    (os/spawn ["xdg-open" (get result :url)] :pd)))

(defn select-bookmark [&opt profile reload?]
  (rofi/chain [r :theme "bookmarkmenu"]
    (let [bookmarks (bookmarks profile reload?)]
      (:add r "<b>Reload bookmarks</b> ->"
            :icon "reload"
            :data (fn [] (select-bookmark profile true)))
      (:div r)
      (each e bookmarks
        (def title (rofi/escape (e :title)))
        (def url (rofi/escape (e :url)))
        (:add r (if (empty? title)
                  (fmt "<b>%s</b>" url)
                  (fmt "<b>%s</b> <span alpha='50%%' size='x-small'>%s</span>" title url))
              :icon (or (e :favicon) "link")
              :data e)))))

(defmain [_ &opts
          profile [--profile name]
          reload? [-r --reload]]
  (open-url (select-bookmark profile reload?)))
