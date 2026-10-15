#!/usr/bin/env janet
# Browse my Grimmory library (books, authors, libraries) via Rofi.
#
# SYNOPSIS:
#   grimmorymenu [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Lists every book on books.home.lissner.net with its cover; picking one opens
#   its page in the browser. `Authors ->` and `Libraries ->` do the same for
#   theirs. The catalogue and covers are cached until `Reload`.
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

(defn- url [& parts] (string "https://" *host* ;parts))


## HTTP

(defn- quoted
  ``S as a curl config string: only backslash and the quote itself need
  escaping, and curl takes \" for the latter.``
  [s]
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
         :library (b :libraryName)
         :library-id (b :libraryId)
         :cover file})))
  (download! (tabseq [[file u] :pairs wanted :unless (path/file? file)] file u))
  (when (path/directory? *covers*)
    (each f (path/files-in *covers*)
      (unless (wanted f) (os/rm f))))
  (def counts (frequencies (map |($0 :library-id) out)))
  # A cover that didn't arrive is no cover at all, as far as rofi's concerned.
  {:books (map |(merge $0 {:cover (when (and ($0 :cover) (path/file? ($0 :cover))) ($0 :cover))}) out)
   :authors (seq [a :in (api/get "/api/v1/authors")
                  # Grimmory keeps a few nameless/garbage authors around from
                  # bad metadata; they'd be blank rows.
                  :unless (empty? (string/trim (or (a :name) "")))]
              {:id (a :id) :name (a :name) :count (get a :bookCount 0)})
   :libraries (sorted-by |(string/ascii-lower ($0 :name))
                (seq [l :in (api/get "/api/v1/libraries")]
                  {:id (l :id) :name (l :name) :count (get counts (l :id) 0)}))})

(defn- catalogue [&opt reload?]
  (:cache *vars* :catalogue fetch-catalogue reload?))


## Rofi

(defn- open-url [u]
  (os/spawn ["xdg-open" u] :pd)
  :opened)

(defn- enter [screen & args]
  (fn [] (let [r (screen ;args)] (if (= r :back) :restart r))))

(defn- small [s]
  (fmt " <span alpha='50%%' size='x-small'>%s</span>" s))

(defn- book-label [b]
  (string "<b>" (rofi/escape (b :title)) "</b>"
          (if (empty? (b :authors)) "" (string " by " (rofi/escape (string/join (b :authors) ", "))))
          (if-let [y (b :year)] (fmt " [%s]" y) "")
          (small (rofi/escape (or (b :library) "")))))

(defn- library-label [l]
  (string (rofi/escape (l :name)) (small (fmt "(%d)" (l :count)))))

(defn- authors-screen []
  (rofi/chain [r :theme *theme* :icon *icon* :prompt "Authors" :placeholder "Search authors..."]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (each a ((catalogue) :authors)
      (:add r (rofi/escape (a :name)) :icon "avatar-default-symbolic"
            :data (fn [] (open-url (url "/author/" (a :id))))))))

(defn- libraries-screen []
  (rofi/chain [r :theme *theme* :icon *icon* :prompt "Libraries" :placeholder "Search libraries..."]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (each l ((catalogue) :libraries)
      (:add r (library-label l) :icon "folder-symbolic"
            :data (fn [] (open-url (url "/library/" (l :id) "/books")))))))

(defn- main-screen []
  (rofi/chain [r :theme *theme* :icon *icon* :prompt "Books" :placeholder "Search books..."]
    (:add r "<b>Reload</b>" :icon "view-refresh-symbolic" :data (fn [] (catalogue true) :restart))
    (:add r "<b>Authors</b> ->" :icon "avatar-default-symbolic" :data (enter authors-screen))
    (:add r "<b>Libraries</b> ->" :icon "folder-symbolic" :data (enter libraries-screen))
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
          (echof "library\t%d\t%s\t%d" (l :id) (l :name) (l :count))))
    (main-screen)))
