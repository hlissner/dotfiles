# lib/hey/romm.janet
#
# RomM (romm.home.lissner.net) houses my library of roms (and non-Steam PC
# games). It manages save files too. This provides a basic API for talking to
# RomM's "win" platform and handling its files. Expects an API key
# (platforms.read, roms.read, assets.read, assets.write) in a custom field
# provided by rbw (bitwarden).

(use ./.)
(use sh)
(import ./rbw)

(def host "romm.home.lissner.net")      # the rbw login too
(def library "/media/nas/media/games")  # its library, when the share is mounted here
(def pseudo-host "romm")                # what push/pull take as HOST for one leg only
(def platform "win")
(def slot "proton")
(def emulator "proton")
(def keep 10)                           # uploads RomM keeps per slot
(def key-field "API Key (hey)")

(def setup-hint
  (string "make one in RomM (Settings > API keys: platforms.read, roms.read, "
          "assets.read, assets.write) and `rbw edit " host "`, custom field \"" key-field "\""))

(defn url [] (or (os/getenv "ROMM_URL") (string "https://" host)))


## HTTP

(var- *key* nil)

(defn api-key []
  (unless *key*
    (unless (or (rbw/unlocked?) (rbw/unlock))
      (abort "Vault is locked"))
    (set *key* (or (some |(when (= ($0 :name) key-field) ($0 :value)) (get (rbw/entry host) :fields []))
                   (abort "%s has no \"%s\" field in rbw; %s" host key-field setup-hint))))
  *key*)

(defn urlencode [s]
  (string (peg/replace-all '(if-not (+ :w (set "-._~")) 1) |(fmt "%%%02X" (first $0)) s)))

(defn api-url [path &opt query]
  (def params (seq [k :in (sorted (keys (or query {}))) :let [v (query k)] :unless (nil? v)]
                (string (urlencode (string k)) "=" (urlencode (string v)))))
  (string (url) path (if (empty? params) "" (string "?" (string/join params "&")))))

(defn- curl-quote [s]
  (string/replace-all `"` `\"` (string/replace-all `\` `\\` s)))

(defn request
  ``curl ARGS, the last of which is the URL, with the key as a header on stdin
  (-K -) so it's never on an argv. The body, or an abort that says which call died.``
  [& args]
  (def out @"")
  (def err @"")
  (def config (fmt "header = \"Authorization: Bearer %s\"\n" (curl-quote (api-key))))
  (if ($? curl -sS -f -K - ,;args < ,config > ,out > [stderr err])
    (string out)
    (case (get (peg/match '(* (thru "error: ") (number :d+)) err) 0)
      401 (abort "RomM rejected the API key; check the \"%s\" field on %s in rbw" key-field host)
      413 (abort "RomM refused the upload as too large (its cap is 512 MiB)")
      (abort "RomM: %s failed: %s" (last args) (string/trim (string err))))))

(defn api-get [path &opt query]
  (json/decode (request (api-url path query)) true true))


## ROMs and saves

(defn platform-id
  "RomM's id for the platform called SLUG."
  [&opt slug]
  (default slug platform)
  (or (get (find |(= ($0 :slug) slug) (api-get "/api/platforms")) :id)
      (abort "RomM has no `%s` platform; add %s/roms/ to its library and rescan" slug slug)))

(defn- rom-record
  "What of RomM's ROM the callers use: its id, file name sans tags, title and file."
  [rom]
  {:id (rom :id)
   :name (rom :fs_name_no_tags)
   :title (or (rom :name) (rom :fs_name_no_tags))
   :file (rom :fs_name)})

(defn find-rom
  ``The ROM on platform PID whose file (tags aside) is called one of NAMES.``
  [names &opt pid]
  (default pid (platform-id))
  (def term (string/trim (first (string/split ":" (first names)))))
  (def wanted (map string/ascii-lower names))
  (def page (api-get "/api/roms" {:platform_ids pid :search_term term :limit 50}))
  (when-let [rom (find |(index-of (string/ascii-lower (or ($0 :fs_name_no_tags) "")) wanted)
                       (get page :items []))]
    (rom-record rom)))

(defn library-file
  ``ROM's file on the share RomM's library is.``
  [rom]
  (def f (path/join (or (os/getenv "ROMM_LIBRARY") library) platform "roms" (rom :file)))
  (when (path/file? f) f))

(defn fetch-rom
  "Download ROM's file to PATH."
  [rom path]
  (request "-o" path (api-url (string "/api/roms/" (rom :id) "/content/" (urlencode (rom :file))))))

(defn roms
  "Every ROM on platform PID by file name."
  [&opt pid]
  (default pid (platform-id))
  (map rom-record (get (api-get "/api/roms" {:platform_ids pid :limit 1000 :order_by "fs_name"}) :items [])))

(defn latest-save
  "ROM-ID's newest save in SLOT (default proton); nil otherwise."
  [rom-id &opt slot*]
  (default slot* slot)
  (last (sort-by |(or ($0 :updated_at) "")
                 (filter |(= ($0 :slot) slot*) (api-get "/api/saves" {:rom_id rom-id})))))

(defn fetch-save [id]
  (request (api-url (string "/api/saves/" id "/content"))))

(defn upload-save
  ``Store BYTES as ROM-ID's proton save called FILE-NAME; the save record RomM
  made. The slot keeps the last few, so an upload never overwrites one.``
  [rom-id file-name bytes]
  (def tmp ($<_ mktemp -p ,(or (os/getenv "TMPDIR") "/tmp") hey-romm.XXXXXX))
  (defer (os/rm tmp)
    (spit tmp bytes)
    (json/decode
     (request "-F" (string "saveFile=@" tmp ";filename=" file-name ";type=application/zip")
              (api-url "/api/saves" {:rom_id rom-id :emulator emulator :slot slot
                                     :autocleanup "true" :autocleanup_limit keep}))
     true true)))
