#!/usr/bin/env janet
# Browse my Grimmory library via Rofi.
#
# SYNOPSIS:
#   grimmorymenu [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Talks to https://books.home.lissner.net. Selecting a book will open its page
#   in the browser.
#
# OPTIONS:
#   -l, --list
#     Print what the menu would show and don't open it.
#   -r, --reload
#     Refetch the catalogue (and any new covers) rather than trust the cache.

(use hey)
(use sh)
(import hey/rbw)
(import hey/rofi)
(import hey/vars)
(import spork/sh :as fs)

# Also the rbw login's name. grimmory.home.lissner.net answers everything with
# an empty 200 (a Caddy stub); the app, the API and its web UI are all here.
(def- *host* "books.home.lissner.net")
(def- *theme* "appmenu.rasi")
(def- *icon* "accessories-dictionary-symbolic")

# The catalogue and covers survive reboots; the token doesn't need to.
(def- *vars*    (vars/new (:dir (vars/global) :rofi :grimmorymenu)))
(def- *covers*  (:dir *vars* :covers))
(def- *session* (vars/new (:dir (vars/temp) :rofi :grimmorymenu)))
(def- *catalogue-version* 2)

(def- *statuses*
  {"UNREAD" "Unread" "READING" "Reading" "RE_READING" "Re-reading" "READ" "Read"
   "PARTIALLY_READ" "Partially read" "PAUSED" "Paused" "WONT_READ" "Won't read"
   "ABANDONED" "Abandoned" "UNSET" "Unset"})

(defn- url [& parts] (string "https://" *host* ;parts))


## HTTP

(defn- quoted [s]
  (string `"` (->> s (string/replace-all `\` `\\`) (string/replace-all `"` `\"`)) `"`))

(defn- curl
  ``CONFIG goes in on stdin (curl -K -), so neither the password nor the token
  ever sits on an argv. Returns the body, or nil on a 401 so the caller can get
  a fresh token; anything else is fatal.``
  [config & args]
  (def out @"")
  (def err @"")
  (if ($? curl -sS -f -K - ,;args < ,config > ,out > [stderr err])
    (string out)
    (if (string/find "error: 401" err)
      nil
      (abort "curl failed: %s" (string/trim err)))))

(defn- login []
  (unless (or (rbw/unlocked?) (rbw/unlock))
    (abort "Vault is locked"))
  (def e (rbw/entry *host*))
  (def body (json/encode {:username (get-in e [:data :username])
                          :password (get-in e [:data :password])}))
  (def r (json/decode
          (or (curl (fmt "header = \"Content-Type: application/json\"\ndata = %s\n" (quoted body))
                    (url "/api/v1/auth/login"))
              (abort "Grimmory rejected the login for %s" *host*))
          true))
  # A minute of slack so a token can't expire between here and the request.
  (:set *session* :token {:token (r :accessToken)
                          :until (+ (os/time) (get r :expires 0) -60)})
  (r :accessToken))

(defn- token [&opt fresh?]
  (def s (unless fresh? (:get *session* :token)))
  (if (and s (< (os/time) (s :until)))
    (s :token)
    (login)))

(defn- auth-header [&opt fresh?]
  (fmt "header = \"Authorization: Bearer %s\"\n" (token fresh?)))

(defn- api/get [path]
  (json/decode (or (curl (auth-header) (url path))
                   (curl (auth-header true) (url path))
                   (abort "Grimmory rejected my token twice; giving up"))
               true))

(defn- api/pages [path]
  (def out @[])
  (var page 0)
  (while true
    (def r (api/get (fmt "%s?page=%d&size=500" path page)))
    (array/concat out (r :content))
    (unless (r :hasNext) (break))
    (++ page))
  out)

(defn- download!
  ``Fetch every URL in FILES ({ path url }) in one parallel curl. A cover that
  404s is left absent rather than fatal: the row simply goes without.``
  [files]
  (unless (empty? files)
    (fs/create-dirs *covers*)
    (def config (buffer (auth-header) "parallel\nparallel-max = 16\nremove-on-error\n"))
    (eachp [file u] files
      (buffer/push config "url = " (quoted u) "\noutput = " (quoted file) "\n"))
    ($? curl -sS -f -K - < ,config > :null > [stderr :null])))


## The catalogue

(defn- year [date]
  (when (and date (>= (length date) 4))
    (string/slice date 0 4)))

(defn- cover-url
  ``Which media endpoint has this book's cover, if any: ebooks and audiobooks
  keep theirs under different names, and the stamp is what the web UI appends
  to bust its own cache.``
  [book]
  (def m (book :metadata))
  (cond (m :coverUpdatedOn) [(url "/api/v1/media/book/" (book :id) "/thumbnail") (m :coverUpdatedOn)]
        (m :audiobookCoverUpdatedOn) [(url "/api/v1/media/book/" (book :id) "/audiobook-thumbnail") (m :audiobookCoverUpdatedOn)]))

(defn- cover-file [book stamp]
  # The stamp in the name means a regenerated cover is a new file, and the
  # sweep below retires the old one.
  (path/join *covers* (fmt "%d.%s.jpg" (book :id) (string/replace-all ":" "." stamp))))

(defn- fetch-catalogue []
  (def books (api/get "/api/v1/books"))
  (def wanted @{})
  (def out
    (sorted-by |(string/ascii-lower ($0 :title))
      (seq [b :in books :let [m (b :metadata)]]
        (def [cover stamp] (or (cover-url b) [nil nil]))
        (def file (when cover (cover-file b stamp)))
        (when file (put wanted file cover))
        {:id (b :id)
         :title (or (m :title) (get-in b [:primaryFile :fileName]) "(untitled)")
         :authors (get m :authors [])
         :year (year (m :publishedDate))
         :series (m :seriesName)
         :series-no (m :seriesNumber)
         :genres (get m :categories [])
         :status (b :readStatus)
         :shelves (map |($0 :id) (get b :shelves []))
         :library (b :libraryName)
         :library-id (b :libraryId)
         :cover file})))
  (download! (tabseq [[file u] :pairs wanted :unless (path/file? file)] file u))
  (when (path/directory? *covers*)
    (each f (path/files-in *covers*)
      (unless (wanted f) (os/rm f))))
  (def counts (frequencies (map |($0 :library-id) out)))
  (defn shelf [s ids &opt magic?]
    {:id (s :id) :name (s :name) :magic? magic? :count (length ids) :books ids})
  # A cover that didn't arrive is no cover at all, as far as rofi's concerned.
  {:version *catalogue-version*
   :books (map |(merge $0 {:cover (when (and ($0 :cover) (path/file? ($0 :cover))) ($0 :cover))}) out)
   :authors (seq [a :in (api/get "/api/v1/authors")
                  # Grimmory keeps a few nameless/garbage authors around from
                  # bad metadata; they'd be blank rows.
                  :unless (empty? (string/trim (or (a :name) "")))]
              {:id (a :id) :name (a :name) :count (get a :bookCount 0)})
   :libraries (sorted-by |(string/ascii-lower ($0 :name))
                (seq [l :in (api/get "/api/v1/libraries")]
                  {:id (l :id) :name (l :name) :count (get counts (l :id) 0)}))
   :shelves (sorted-by |(string/ascii-lower ($0 :name))
              (array/concat
               (seq [s :in (api/get "/api/v1/app/shelves")]
                 (shelf s (seq [b :in out :when (index-of (s :id) (b :shelves))] (b :id))))
               # A magic shelf is a filter, so no book admits to being on one;
               # only the server can say, one shelf at a time.
               (seq [s :in (api/get "/api/v1/app/shelves/magic")]
                 (shelf s (map |($0 :id) (api/pages (string "/api/v1/app/shelves/magic/" (s :id) "/books")))
                        true))))})

(defn- catalogue [&opt reload?]
  (def c (:cache *vars* :catalogue fetch-catalogue reload?))
  (if (= (c :version) *catalogue-version*) c (catalogue true)))

(defn- books-with [ids]
  (def want (tabseq [i :in ids] i true))
  (filter |(want ($0 :id)) ((catalogue) :books)))

(defn- grouped
  ``The catalogue's books bucketed by every value F yields for one (without
  nils), as {:name :count :books} entries sorted by name.``
  [f]
  (def t @{})
  (each b ((catalogue) :books)
    (each k (f b)
      (when k (update t k |(array/push (or $ @[]) b)))))
  (sorted-by |(string/ascii-lower ($0 :name))
    (seq [[k bs] :pairs t] {:name k :count (length bs) :books bs})))

(defn- status-label [s] (get *statuses* (or s "UNSET") s))

(defn- series   [] (grouped |[($0 :series)]))
(defn- genres   [] (grouped |($0 :genres)))
(defn- statuses [] (grouped |[(status-label ($0 :status))]))
(defn- years    [] (reverse (grouped |[($0 :year)])))


## Rofi

(defn- open-url [u]
  (os/spawn ["xdg-open" u] :pd)
  :opened)

(defn- enter [screen & args]
  (fn [] (let [r (screen ;args)] (if (= r :back) :restart r))))

(defn- small [s]
  (fmt ` <span alpha="50%%" size="x-small">%s</span>` s))

(defn- strip-tags [s]
  (string (peg/replace-all '(* "<" (to ">") ">") "" s)))

(defn- book-label [b]
  (string "<b>" (rofi/escape (b :title)) "</b>"
          (if (empty? (b :authors)) "" (string " by " (rofi/escape (string/join (b :authors) ", "))))
          (if-let [y (b :year)] (fmt " [%s]" y) "")
          (small (rofi/escape (or (b :library) "")))))

(defn- counted-label [g]
  (string (rofi/escape (g :name)) (small (fmt "(%d)" (g :count)))))

(defn- series-label [b]
  (string (if-let [n (b :series-no)] (fmt "<span alpha=\"60%%\">#%g:</span> " n) "") (book-label b)))

(defn- books-screen
  ``BOOKS under PROMPT, after Back and any ACTIONS ([label icon thunk]),
  each captioned by LABEL (book-label unless told otherwise).``
  [prompt books &named message actions label]
  (rofi/chain [r :theme *theme* :icon *icon* :prompt prompt :placeholder "Search books..." :message message]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (each [label icon f] (or actions [])
      (:add r (fmt "<b>%s</b> ->" label) :icon icon :data f))
    (:div r)
    (each b books
      (:add r ((or label book-label) b)
            ;(opts :icon (b :cover))
            :data (fn [] (open-url (url "/book/" (b :id))))))))

(defn- group-screen
  ``GROUPS ({:name :count ...}) under PROMPT; picking one hands it to OPEN,
  a screen of its own. ICON may be a function of the group.``
  [prompt icon groups open]
  (rofi/chain [r :theme *theme* :icon *icon* :prompt prompt
               :placeholder (fmt "Search %s..." (string/ascii-lower prompt))]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (each g groups
      (:add r (counted-label g) :icon (if (function? icon) (icon g) icon)
            :data (enter open g)))))

(defn- library-screen [l]
  (books-screen (l :name) (filter |(= ($0 :library-id) (l :id)) ((catalogue) :books))
                :actions [["Open in Browser" "web-browser-symbolic"
                           (fn [] (open-url (url "/library/" (l :id) "/books")))]]))

(defn- author-screen [a]
  # The bio only comes from the detail endpoint, one author per request, so it's
  # asked for here rather than hoarded in the catalogue.
  (def bio (string/trim (or ((api/get (string "/api/v1/authors/" (a :id))) :description) "")))
  (books-screen (a :name) (filter |(index-of (a :name) ($0 :authors)) ((catalogue) :books))
                :message (unless (empty? bio) (rofi/escape (strip-tags bio)))
                :actions [["Open in Browser" "web-browser-symbolic"
                           (fn [] (open-url (url "/author/" (a :id))))]]))

(defn- libraries-screen []
  (group-screen "Libraries" "folder-symbolic" ((catalogue) :libraries) library-screen))

(defn- authors-screen []
  (group-screen "Authors" "avatar-default-symbolic" ((catalogue) :authors) author-screen))

(defn- shelves-screen []
  (group-screen "Shelves" |(if ($0 :magic?) "starred-symbolic" "bookmark-new-symbolic")
                ((catalogue) :shelves)
                (fn [s] (books-screen (s :name) (books-with (s :books))))))

(defn- series-screen []
  # Unnumbered volumes sink to the end, still alphabetical among themselves.
  (group-screen "Series" "view-list-symbolic" (series)
                (fn [g] (books-screen (g :name) (sort-by |(or ($0 :series-no) math/inf) (array ;(g :books)))
                                      :label series-label))))

(defn- grouped-screen [prompt icon groups]
  (group-screen prompt icon (groups) (fn [g] (books-screen (g :name) (g :books)))))

(defn- main-screen []
  (rofi/chain [r :theme *theme* :icon *icon* :prompt "Books" :placeholder "Search books..."]
    (:add r "<b>Reload</b>" :icon "view-refresh-symbolic" :data (fn [] (catalogue true) :restart))
    (:add r "<b>Open in Browser</b> ->" :icon "web-browser-symbolic" :data (fn [] (open-url (url))))
    (:add r "<b>By Library</b> ->" :icon "folder-symbolic" :data (enter libraries-screen))
    (:add r "<b>By Author</b> ->" :icon "avatar-default-symbolic" :data (enter authors-screen))
    (:add r "<b>By Series</b> ->" :icon "view-list-symbolic" :data (enter series-screen))
    (:add r "<b>By Shelf</b> ->" :icon "bookmark-new-symbolic" :data (enter shelves-screen))
    (:add r "<b>By Genre</b> ->" :icon "tag-symbolic" :data (enter grouped-screen "Genres" "tag-symbolic" genres))
    (:add r "<b>By Read Status</b> ->" :icon "emblem-ok-symbolic" :data (enter grouped-screen "Read Statuses" "emblem-ok-symbolic" statuses))
    (:add r "<b>By Published Year</b> ->" :icon "x-office-calendar-symbolic" :data (enter grouped-screen "Published Years" "x-office-calendar-symbolic" years))
    (:div r)
    (each b ((catalogue) :books)
      (:add r (book-label b)
            ;(opts :icon (b :cover))
            :data (fn [] (open-url (url "/book/" (b :id))))))))

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  (def cat (catalogue reload?))
  (if list?
    (do (each b (cat :books)
          (echof "book\t%d\t%s\t%s\t%s\t%s\t%s" (b :id) (b :title) (string/join (b :authors) ", ")
                 (or (b :year) "") (or (b :library) "") (or (b :cover) "")))
        (each a (cat :authors)
          (echof "author\t%d\t%s\t%d" (a :id) (a :name) (a :count)))
        (each l (cat :libraries)
          (echof "library\t%d\t%s\t%d" (l :id) (l :name) (l :count)))
        (each s (cat :shelves)
          (echof "%s\t%d\t%s\t%d" (if (s :magic?) "magic-shelf" "shelf") (s :id) (s :name) (s :count)))
        (each [kind groups] [["series" series] ["genre" genres] ["status" statuses] ["year" years]]
          (each g (groups)
            (echof "%s\t%s\t%d" kind (g :name) (g :count)))))
    (main-screen)))
