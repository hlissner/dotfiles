#!/usr/bin/env janet
# Browse my Homebox inventory via Rofi.
#
# SYNOPSIS:
#   homeboxmenu [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Picking an item opens a second menu: open it in the browser, copy any of its
#   fields, or open one of its attachments.
#
#   Credentials are the rbw login named after the host. Its "API Key (hey)"
#   custom field is preferred; without one, the password logs in.
#
# OPTIONS:
#   -l, --list
#     Print what the menu would show and don't open it.
#   -r, --reload
#     Refetch the item list rather than trust the cache.

(use hey)
(use sh)
(import hey/rbw)
(import hey/rofi)
(import hey/sys)
(import hey/vars)
(import spork/sh :as fs)

(def- *host* "inventory.home.lissner.net")
(def- *url* (string "https://" *host*))
(def- *theme* "homeboxmenu.rasi")
(def- *item-icon* "package-x-generic")

# The item list survives a reboot; the session token does not.
(def- *vars*    (vars/new (:dir (vars/global) :rofi :homeboxmenu)))
(def- *icons*   (vars/new (:dir *vars* :icons) true))
(def- *session* (vars/new (:dir (vars/temp) :rofi :homeboxmenu)))

(defn- val [v]
  (unless (or (nil? v) (= v :null) (= v "")) v))


## Credentials

(var- *entry* nil)
(defn- entry []
  (or *entry* (set *entry* (rbw/entry *host*))))

(defn- api-key
  ``Homebox takes an API key as a bearer token like any session token, and
  unlike one it doesn't expire under me mid-menu.``
  []
  (some |(when (= ($0 :name) "API Key (hey)") (val ($0 :value)))
        (get (entry) :fields [])))


## HTTP

(defn- curl-quote
  ``curl -K's double-quoted strings understand \" and \\, and nothing I need
  beyond those.``
  [s]
  (string/replace-all `"` `\"` (string/replace-all `\` `\\` s)))

(defn- curl
  ``Run curl with CONFIG (curl -K syntax) on stdin, so neither the password nor
  the token ever sits on an argv. Returns [EXIT-CODE BODY].``
  [config & args]
  (def out @"")
  (def err @"")
  (if ($? curl -sS -f -K - ,;args < ,config > ,out > [stderr err])
    [0 (string out)]
    [(if (string/find "The requested URL returned error: 401" err) 401 1)
     (string/trim err)]))

(defn- login []
  (def e (entry))
  (def body (json/encode {:username (get-in e [:data :username])
                          :password (get-in e [:data :password])
                          :stayLoggedIn false}))
  (def [code out]
    (curl (fmt "header = \"Content-Type: application/json\"\ndata = \"%s\"\n"
               (curl-quote (string body)))
          (string *url* "/api/v1/users/login")))
  (unless (zero? code)
    (abort "Couldn't log into %s: %s" *host* out))
  (def token (or (get (json/decode out true) :token)
                 (abort "No token in %s's login response" *host*)))
  # The token comes back already prefixed with "Bearer "; older builds didn't.
  (:set *session* :token (if (string/has-prefix? "Bearer " token)
                           token
                           (string "Bearer " token))))

(defn- token []
  (if-let [key (api-key)]
    (string "Bearer " key)
    (or (:get *session* :token) (login))))

(defn- request
  ``curl ARGS authenticated. A 401 on a session token means it expired, so log
  in once more; on a key it means I revoked it, and nothing here fixes that.
  Returns [EXIT-CODE BODY-OR-ERROR].``
  [& args]
  (def [code out] (curl (fmt "header = \"Authorization: %s\"\n" (curl-quote (token))) ;args))
  (if (and (= code 401) (not (api-key)))
    (curl (fmt "header = \"Authorization: %s\"\n" (curl-quote (login))) ;args)
    [code out]))

(defn- authed
  ``request, but a failure is fatal and says which URL it was.``
  [& args]
  (def [code out] (request ;args))
  (if (zero? code)
    out
    (abort "curl failed (%s): %s" (last args) out)))

(defn- url [path & query]
  (string *url* "/api/v1" path
          (if (empty? query) "" (string "?" (string/join query "&")))))

(defn- tenant
  ``The query that points a request at COLLECTION (a group id). Without it the
  server assumes my default one, which is what the main list shows.``
  [collection]
  (if collection [(string "tenant=" collection)] []))

(defn- api [path & query]
  (json/decode (authed (url path ;query)) true))

(defn- download!
  ``Fetch PATH into FILE. Fatal unless SOFT, which gets nil instead.``
  [path file &named soft query]
  (fs/create-dirs (path/dirname file))
  (def u (url path ;(or query [])))
  (if soft
    (let [[code out] (request "-o" file u)]
      (if (zero? code)
        file
        (do (ignore-errors (os/rm file))
            (when (debug?) (echof :debug "%s: %s" u out))
            nil)))
    (do (authed "-o" file u)
        file)))


## Items

(defn- oneline [s]
  (def flat (string/replace-all "\n" " " (string/trim s)))
  (if (> (length flat) 60) (string (string/slice flat 0 59) "…") flat))

(defn- attachment-path [item-id attachment-id]
  # Since 0.26 everything, locations included, is an "entity".
  (fmt "/entities/%s/attachments/%s" item-id attachment-id))

(defn- icon-file
  ``The item's primary photo, fetched once into the cache and squeezed through
  magick: the server's thumbnails are webp, which rofi's gdk-pixbuf has no
  loader for, and the full photo is whatever size my phone felt like. A miss
  means the generic icon; one 404 must not take the whole list down.``
  [item collection]
  (some (fn [img]
          (def file (:file *icons* (string (item :id) "-" img ".png")))
          (def raw (:file *icons* (string (item :id) "-" img)))
          (or (when (path/file? file) file)
              (when (download! (attachment-path (item :id) img) raw
                               :soft true :query (tenant collection))
                (defer (ignore-errors (os/rm raw))
                  (when ($? magick ,raw -thumbnail x96 ,file > :null > [stderr :null])
                    file)))))
        (filter truthy? [(val (item :thumbnailId)) (val (item :imageId))])))

# Bump when the cached shape changes, so a stale cache refetches instead of
# handing nils to whatever reads the new field.
(def- *inventory-version* 4)

(defn- fetch-entities
  ``Every page of /entities?QUERY; total is the authority on when to stop.``
  [& query]
  (def all @[])
  (var page 1)
  (var total nil)
  (while (or (nil? total) (< (length all) total))
    (def res (api "/entities" "pageSize=500" (string "page=" page) ;query))
    (def items (get res :items []))
    (when (empty? items) (break))
    (set total (res :total))
    (array/concat all items)
    (++ page))
  all)

(defn- fetch-items [collection]
  (seq [it :in (fetch-entities ;(tenant collection))
        :unless (get-in it [:entityType :isLocation])]
    {:id (it :id)
     :name (or (val (it :name)) "(unnamed)")
     :location (-?> (it :parent) val (get :name) val)
     :parent (-?> (it :parent) val (get :id))
     :tags (map |($0 :id) (get it :tags []))
     :collection collection
     :icon (icon-file it collection)}))

(defn- fetch-inventory []
  # The UI calls groups "collections": separate inventories, one of them my
  # default, which is all the server shows unless a request names another.
  # Locations and tags are only gathered for the default; the others are
  # browsed whole.
  (def me (get (api "/users/self") :item {}))
  {:version *inventory-version*
   :default (me :defaultGroupId)
   :collections (seq [g :in (api "/groups/all")]
                  {:id (g :id)
                   :name (or (val (g :name)) "(unnamed)")
                   :items (fetch-items (unless (= (g :id) (me :defaultGroupId)) (g :id)))})
   # Locations are entities too, but the list leaves them out unless asked, and
   # the asking (isLocation=true) is in the handler, not the swagger.
   :locations (seq [it :in (fetch-entities "isLocation=true")]
                {:id (it :id)
                 :name (or (val (it :name)) "(unnamed)")
                 :parent (-?> (it :parent) val (get :id))})
   # From /tags rather than the items, so an unused tag still lists.
   :tags (seq [t :in (api "/tags")]
           {:id (t :id) :name (or (val (t :name)) "(unnamed)")})})

(defn- inventory [&opt reload?]
  (when reload? (:clear *icons*))
  (def inv (:cache *vars* :inventory fetch-inventory reload?))
  (if (= (inv :version) *inventory-version*) inv (inventory true)))

(defn- items
  "The default collection's items."
  []
  (def inv (inventory))
  (get (find |(= ($0 :id) (inv :default)) (inv :collections)) :items []))

(defn- label [item]
  (fmt "%s%s"
       (rofi/escape (item :name))
       (if-let [loc (item :location)]
         (fmt " <span alpha='50%%' size='x-small'>(%s)</span>" (rofi/escape loc))
         "")))

(defn- lineage
  ``Every id above ENTITY in PARENTS (id -> parent id), nearest first. Nothing
  server-side stops a cycle, so give up at a depth no shelf has.``
  [entity parents]
  (def ids @[])
  (var p (entity :parent))
  (while (and p (< (length ids) 32))
    (array/push ids p)
    (set p (parents p)))
  ids)

(defn- grouped
  ``The items bucketed under every key F yields for one.``
  [f]
  (def t @{})
  (each it (items)
    (each k (f it)
      (update t k |(array/push (or $ @[]) it))))
  t)

(defn- by-name [xs]
  (sorted-by |(string/ascii-lower ($0 :name)) xs))

(defn- by-location
  ``Locations as {:name :items}, named by their full path since "Drawer 1" on
  its own could be any of them. Items in a box on a shelf in a room belong to
  the room too; that's what "where is it" asks.``
  []
  (def inv (inventory))
  (def parents (tabseq [e :in [;(inv :locations) ;(inv :items)]] (e :id) (e :parent)))
  (def names (tabseq [l :in (inv :locations)] (l :id) (l :name)))
  (def under (grouped |(lineage $0 parents)))
  (by-name
   (seq [l :in (inv :locations)]
     {:name (string/join [;(reverse (keep |(names $0) (lineage l parents))) (l :name)] " / ")
      :items (by-name (get under (l :id) @[]))})))

(defn- by-tag []
  (def with (grouped |($0 :tags)))
  (by-name
   (seq [t :in ((inventory) :tags)]
     {:name (t :name) :items (by-name (get with (t :id) @[]))})))

(defn- by-collection []
  (by-name (seq [c :in ((inventory) :collections)]
             {:name (c :name) :items (by-name (c :items))})))


## One item

(defn- copy! [what value]
  (if (sys/yank value)
    (sys/notify (oneline value) :title (fmt "Copied %s" what) :icon "edit-copy-symbolic" :sound "blip")
    (sys/notify (fmt "Couldn't copy %s" what) :urgency "critical" :icon "dialog-error-symbolic"))
  :copied)

(defn- open-url [url]
  (os/spawn ["xdg-open" url] :pd)
  :opened)

(defn- date [s]
  # Homebox's null date is year 1, and the frontend hides it the same way.
  (when-let [s (val s)]
    (unless (string/has-prefix? "0001-" s)
      (string/slice s 0 10))))

(defn- bool [b]
  (case b true "Yes" false "No"))

(defn- money [n]
  (when (and (number? n) (> n 0)) (string n)))

(defn- custom-value [f]
  (case (f :type)
    "number" (-?> (f :numberValue) val string)
    "boolean" (bool (f :booleanValue))
    "time" (date (f :textValue))
    (val (f :textValue))))

(defn- field-rows
  "[LABEL VALUE ICON] for every field of ITEM that's set, custom ones last."
  [item]
  (def rows
    [["Quantity" (-?> (item :quantity) val string) "view-list-symbolic"]
     ["Serial number" (item :serialNumber) "dialog-password-symbolic"]
     ["Model number" (item :modelNumber) "text-x-generic-symbolic"]
     ["Manufacturer" (item :manufacturer) "emblem-system-symbolic"]
     ["Insured" (bool (item :insured)) "security-high-symbolic"]
     ["Archived" (bool (item :archived)) "folder-symbolic"]
     ["Asset ID" (item :assetId) "tag-symbolic"]
     ["Purchased from" (item :purchaseFrom) "emblem-shared-symbolic"]
     ["Purchase price" (money (item :purchasePrice)) "emblem-money-symbolic"]
     ["Purchase date" (date (item :purchaseDate)) "x-office-calendar-symbolic"]
     ["Lifetime warranty" (when (item :lifetimeWarranty) "Yes") "emblem-default-symbolic"]
     ["Warranty expires" (unless (item :lifetimeWarranty) (date (item :warrantyExpires))) "x-office-calendar-symbolic"]
     ["Warranty details" (item :warrantyDetails) "text-x-generic-symbolic"]
     ["Sold to" (item :soldTo) "emblem-shared-symbolic"]
     ["Sold price" (money (item :soldPrice)) "emblem-money-symbolic"]
     ["Sold date" (date (item :soldDate)) "x-office-calendar-symbolic"]
     ["Sold notes" (item :soldNotes) "text-x-generic-symbolic"]
     ["Notes" (item :notes) "notes-panel"]
     ;(seq [f :in (get item :fields [])]
        [(or (val (f :name)) "Field") (custom-value f) "text-x-generic-symbolic"])])
  (filter |(val ($0 1)) rows))

(defn- attachment-name [a]
  (or (val (a :title))
      (-?> (a :path) val path/basename)
      (a :id)))

(defn- open-attachment!
  ``Attachments sit behind the API token, which the browser hasn't got, so pull
  the file down and hand xdg-open the copy.``
  [summary item a]
  (def file (:file *icons* (string (item :id) "-" (a :id) "-" (attachment-name a))))
  (unless (path/file? file)
    (download! (attachment-path (item :id) (a :id)) file :query (tenant (summary :collection))))
  (open-url file))

(defn- item-screen [summary]
  (def item (api (string "/entities/" (summary :id)) ;(tenant (summary :collection))))
  (def name (summary :name))
  (def tags (map |($0 :name) (get item :tags [])))
  (rofi/chain [r :theme *theme* :prompt name
               :message (-?> (item :description) val rofi/escape)]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:add r "<b>Open in Browser</b> ->" :icon "web-browser-symbolic"
          :data (fn [] (open-url (fmt "%s/item/%s" *url* (item :id)))))
    (unless (empty? tags)
      (def joined (string/join tags ", "))
      (:add r (fmt "<b>Tags:</b> %s" (rofi/escape joined))
            :icon "tag-symbolic"
            :data (fn [] (copy! (fmt "tags of %s" name) joined))))
    (:div r)
    (each [label value icon] (field-rows item)
      (:add r (fmt "<b>%s:</b> %s" (rofi/escape label) (rofi/escape (oneline value)))
            :icon icon
            :data (fn [] (copy! (fmt "%s of %s" (string/ascii-lower label) name) value))))
    # Each photo's thumbnail is nested under it, not listed, but no harm making
    # sure a derived file never shows up as an attachment of its own.
    (def attachments (filter |(not= ($0 :type) "thumbnail") (get item :attachments [])))
    (unless (empty? attachments)
      (:div r)
      (each a attachments
        (:add r (fmt "<b>Attachment:</b> %s <span alpha='50%%' size='x-small'>(%s)</span>"
                     (rofi/escape (attachment-name a))
                     (rofi/escape (or (val (a :type)) "attachment")))
              :icon (if (= (a :type) "photo") "image-x-generic-symbolic" "mail-attachment-symbolic")
              :data (fn [] (open-attachment! summary item a)))))))

(defn- enter [screen & args]
  (fn [] (let [r (screen ;args)] (if (= r :back) :restart r))))

(defn- items-screen [prompt items]
  (rofi/chain [r :theme *theme* :prompt prompt]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (each item items
      (:add r (label item)
            :icon (or (item :icon) *item-icon*)
            :data (enter item-screen item)))))

(defn- groups-screen
  ``GROUPS, a function of no arguments yielding {:name :items} entries, each
  with its count; picking one lists its items.``
  [prompt icon groups]
  (rofi/chain [r :theme *theme* :prompt prompt]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (each g (groups)
      (:add r (fmt `%s <span alpha="50%%" size="x-small">(%d)</span>`
                   (rofi/escape (g :name)) (length (g :items)))
            :icon icon
            :data (enter items-screen (g :name) (g :items))))))


## Main

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  (unless (or (rbw/unlocked?) (rbw/unlock))
    (abort "Vault is locked"))
  # Fetch (or refetch) up front; the chain re-reads the cache on every restart.
  (inventory reload?)
  (if list?
    (each item (items)
      (echof "%s\t%s\t%s\t%s" (item :name) (or (item :location) "") (item :id) (or (item :icon) "")))
    (rofi/chain [r :theme *theme* :prompt "Inventory"]
      (:add r "<b>Reload</b>" :icon "view-refresh-symbolic" :data (fn [] (inventory true) :restart))
      (:add r "<b>Open in Browser</b> ->" :icon "web-browser-symbolic" :data (fn [] (open-url *url*)))
      (:add r "<b>By Location</b> ->" :icon "folder-symbolic" :data (enter groups-screen "Locations" "folder-symbolic" by-location))
      (:add r "<b>By Tag</b> ->" :icon "tag-symbolic" :data (enter groups-screen "Tags" "tag-symbolic" by-tag))
      (:add r "<b>By Collection</b> ->" :icon "go-home-symbolic" :data (enter groups-screen "Collections" "go-home-symbolic" by-collection))
      (:div r)
      (each item (items)
        (:add r (label item)
              :icon (or (item :icon) *item-icon*)
              :data (enter item-screen item))))))
