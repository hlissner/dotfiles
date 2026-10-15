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

(defn- api [path & query]
  (json/decode (authed (string *url* "/api/v1" path
                               (if (empty? query) ""
                                 (string "?" (string/join query "&")))))
               true))

(defn- download!
  ``Fetch PATH into FILE. Fatal unless SOFT, which gets nil instead.``
  [path file &named soft]
  (fs/create-dirs (path/dirname file))
  (def url (string *url* "/api/v1" path))
  (if soft
    (let [[code out] (request "-o" file url)]
      (if (zero? code)
        file
        (do (ignore-errors (os/rm file))
            (when (debug?) (echof :debug "%s: %s" url out))
            nil)))
    (do (authed "-o" file url)
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
  [item]
  (some (fn [img]
          (def file (:file *icons* (string (item :id) "-" img ".png")))
          (def raw (:file *icons* (string (item :id) "-" img)))
          (or (when (path/file? file) file)
              (when (download! (attachment-path (item :id) img) raw :soft true)
                (defer (ignore-errors (os/rm raw))
                  (when ($? magick ,raw -thumbnail x96 ,file > :null > [stderr :null])
                    file)))))
        (filter truthy? [(val (item :thumbnailId)) (val (item :imageId))])))

(defn- fetch-items []
  # Paginated; total is the authority on when to stop. The list doesn't hand
  # back locations today, but they're entities too, so don't trust that.
  (def all @[])
  (var page 1)
  (var total nil)
  (while (or (nil? total) (< (length all) total))
    (def res (api "/entities" "pageSize=500" (string "page=" page)))
    (def items (get res :items []))
    (when (empty? items) (break))
    (set total (res :total))
    (array/concat all items)
    (++ page))
  (seq [it :in all :unless (get-in it [:entityType :isLocation])]
    {:id (it :id)
     :name (or (val (it :name)) "(unnamed)")
     :location (-?> (it :parent) val (get :name) val)
     :icon (icon-file it)}))

(defn- items [&opt reload?]
  (when reload? (:clear *icons*))
  (:cache *vars* :items fetch-items reload?))

(defn- label [item]
  (fmt "%s%s"
       (rofi/escape (item :name))
       (if-let [loc (item :location)]
         (fmt " <span alpha='50%%' size='x-small'>(%s)</span>" (rofi/escape loc))
         "")))


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
  [item a]
  (def file (:file *icons* (string (item :id) "-" (a :id) "-" (attachment-name a))))
  (unless (path/file? file)
    (download! (attachment-path (item :id) (a :id)) file))
  (open-url file))

(defn- item-screen [summary]
  (def item (api (string "/entities/" (summary :id))))
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
              :data (fn [] (open-attachment! item a)))))))

(defn- enter [screen & args]
  (fn [] (let [r (screen ;args)] (if (= r :back) :restart r))))


## Main

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  (unless (or (rbw/unlocked?) (rbw/unlock))
    (abort "Vault is locked"))
  # Fetch (or refetch) up front; the chain re-reads the cache on every restart.
  (items reload?)
  (if list?
    (each item (items)
      (echof "%s\t%s\t%s\t%s" (item :name) (or (item :location) "") (item :id) (or (item :icon) "")))
    (rofi/chain [r :theme *theme* :prompt "Inventory"]
      (:add r "<b>Reload</b>" :icon "view-refresh-symbolic" :data (fn [] (items true) :restart))
      (:div r)
      (each item (items)
        (:add r (label item)
              :icon (or (item :icon) *item-icon*)
              :data (enter item-screen item))))))
