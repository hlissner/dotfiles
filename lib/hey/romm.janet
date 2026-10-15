# lib/hey/romm.janet
#
# Keep a device's emulator files in step with RomM. The verbs in bin/romm.d/
# are thin; what they do lives here, split in two: the builders decide what to
# run and never touch the network or a device (that half the suite pins), the
# runners with a ! do the touching.
#
# RomM's library is the NAS, which udon mounts, so ROMs never go over HTTP:
# the API only says *which* files a device gets, and rsync moves them off the
# mount. Saves do go through the API, via RomM's own device-sync protocol, so
# the server is the arbiter and I don't write a three-way merge.

(use ./.)
(import ./vars)
(import ./rbw)
(import spork/sh :as fs)

(def- *library* "/media/nas/media/games")
(def- *entry* "romm.home.lissner.net")   # the rbw login; its name is the host

(defn url-base []
  (or (os/getenv "ROMM_URL") (string "https://" *entry*)))


## Profiles

# ES-DE's folder names where they differ from RomM's slugs; the rest are the
# same word on both sides. Mirrors the overrides in hosts/udon/default.nix,
# plus what's on the NAS that udon's module doesn't bother with yet. win/ is
# not an emulator's.
(def- es-de-dirs
  (merge (tabseq [s :in ["nes" "snes" "genesis" "gamegear" "gba" "nds" "n64" "saturn"
                         "psx" "psp" "ps2" "ps3" "wii" "psvita" "switch"]]
           s s)
         {"sms" "mastersystem" "dc" "dreamcast" "ngc" "gc" "3ds" "n3ds" "pico" "pico8"}))

# RetroArch's "sort saves by core" directories are the cores' display names.
# Used only to place a save pulled down for a ROM the device has never saved
# for; an existing save's directory always wins.
(def- es-de-cores
  {"nes" "Mesen" "snes" "Snes9x" "genesis" "Genesis Plus GX"
   "sms" "Genesis Plus GX" "gamegear" "Genesis Plus GX" "gba" "mGBA"
   "n64" "Mupen64Plus-Next" "saturn" "Beetle Saturn" "psx" "Beetle PSX HW"
   "psp" "PPSSPP" "dc" "Flycast" "nds" "melonDS DS"})

# NextUI's Roms/ folders, "Name (TAG)". The tag is what Bios/ and Saves/ key
# on. Whatever isn't here is reported as unmapped; add it off the card.
(def- nextui-dirs
  {"nes" "Nintendo Entertainment System (FC)"
   "snes" "Super Nintendo Entertainment System (SFC)"
   "gb" "Game Boy (GB)"
   "gbc" "Game Boy Color (GBC)"
   "gba" "Game Boy Advance (GBA)"
   "genesis" "Sega Genesis (MD)"
   "sms" "Sega Master System (SMS)"
   "gamegear" "Sega Game Gear (GG)"
   "psx" "Sony PlayStation (PS)"
   "pce" "TurboGrafx-16 (PCE)"
   "pico" "Pico-8 (PICO)"})

# sdcardfs fakes ownership and can't set mtimes, so size is the only thing
# worth comparing. FAT can't do perms either, and rounds mtimes to 2s.
(def- android-rsync ["--no-perms" "--no-owner" "--no-group" "--omit-dir-times" "--size-only"])
(def- fat-rsync     ["--no-perms" "--no-owner" "--no-group" "--modify-window=2"])

(defn- emudeck
  ``EmuDeck's layout under ROOT: roms/, a flat bios/ (what the NAS's _bios/
  mirrors), and saves/retroarch/{saves,states}/CORE/. DroidDeck copies it.``
  [root]
  {:roms   {:root (string root "/roms") :dirs es-de-dirs}
   :bios   {:root (string root "/bios") :from :flat}
   # Engines EmuDeck can't install: PICO-8 is a paid blob, so it sits in its
   # platform's bios/ on the NAS, one build per directory (udon runs amd64/
   # too, see modules/games/emulators.nix), and lands where ES-DE's find
   # rules look.
   :apps   {"pico" {:from "amd64" :to "Applications/pico-8"}}
   :saves  {:emulator "retroarch" :dir (string root "/saves/retroarch/saves")
            :layout :by-core :cores es-de-cores}
   :states {:emulator "retroarch" :dir (string root "/saves/retroarch/states")
            :layout :by-core :cores es-de-cores}})

# A path that doesn't start with / is relative to the target's $HOME: the
# remote shell isn't involved, so ~ wouldn't expand there anyway. :target is a
# host (ssh), a directory (a mounted card), or nil (this machine); :user only
# because none of these boxes know me as hlissner.
(def profiles
  {"udon"    {:target nil
              # ROMs and BIOS are the NFS mount itself; see modules/games/emulators.nix.
              :saves  {:emulator "retroarch" :dir ".config/retroarch/saves" :layout :flat}
              :states {:emulator "retroarch" :dir ".config/retroarch/states" :layout :flat}}
   "machine" (merge (emudeck "Emulation") {:target "machine.lan"})
   "deck"    (merge (emudeck "Emulation") {:target "deck.lan" :user "deck"})
   "rp6"     (-> (merge (emudeck "storage/shared/Emulation")
                        {:target "rp6.lan" :ssh ["-p" "8022"] :rsync android-rsync})
                 # Lodor does saves on Android, and the engines are x86. Not
                 # merged in as nils: a struct literal silently drops those.
                 (put :apps nil) (put :saves nil) (put :states nil))
   "brick"   {:target "brick.lan" :rsync fat-rsync
              :roms {:root "/mnt/SDCARD/Roms" :dirs nextui-dirs}
              :bios {:root "/mnt/SDCARD/Bios" :from :platform}
              # The PICO.pak wants the Raspberry Pi build, and only pico8_64
              # and pico8.dat of it, in the folder's tag.
              :apps {"pico" {:from "arm" :to "/mnt/SDCARD/Bios/PICO"
                             :files ["pico8_64" "pico8.dat"]}}}})

(defn devices [] (sorted (keys profiles)))

(defn profile [name]
  (if-let [p (get profiles name)]
    (merge {:name name :collection (string "Device: " name)} p)
    (abort "No such device: %s (one of %s)" name (string/join (devices) ", "))))

(defn remote? [p]
  (let [t (p :target)]
    (truthy? (and t (not (string/has-prefix? "/" t))))))

(defn ssh-target [p]
  (string (if-let [u (p :user)] (string u "@") "") (p :target)))

(defn resolve-path
  ``PATH as the target sees it, absolute. Relative paths hang off $HOME: ours,
  or a mounted card's root.``
  [p path]
  (cond (string/has-prefix? "/" path) path
        (remote? p) path
        (p :target) (path/join (p :target) path)
        (path/join (os/getenv "HOME") path)))

(defn dest
  ``An rsync destination for PATH on P, with the trailing slash rsync wants
  for "the contents of".``
  [p path]
  (let [path (string (resolve-path p path) "/")]
    (if (remote? p) (string (ssh-target p) ":" path) path)))

(defn nextui/tag "\"Game Boy Advance (GBA)\" -> \"GBA\"" [folder]
  (if-let [[tag] (peg/match '(* (any (if-not "(" 1)) "(" (<- (any (if-not ")" 1))) ")" -1)
                              folder)]
    tag
    folder))


## Builders

(defn- escape-rule [name]
  # rsync's filter patterns are globs; ROM sets are full of [!] and (USA).
  (reduce (fn [s c] (string/replace-all c (string "\\" c) s))
          name ["\\" "*" "?" "["]))

(defn include-rules
  ``FILES (names relative to the source dir; a trailing / marks a directory
  taken whole) as NUL-joined anchored rsync include rules. Anchored so a name
  only matches at the top, and a directory gets a second rule for its
  contents.``
  [files]
  (string/join
   (catseq [f :in files :let [r (escape-rule f)]]
     (if (string/has-suffix? "/" f)
       [(string "+ /" r) (string "+ /" r "**")]
       [(string "+ /" r)]))
   "\0"))

(defn rsync-argv
  ``The rsync for one directory. LIST is a rules file from include-rules;
  without it the whole of SRC goes. PRUNE deletes what the rules don't name.
  Not -a: no links, perms or owners, which Android and FAT both reject; EXEC
  keeps just the executable bit, for a leg that carries binaries.``
  [p src dest &named list prune exec]
  [;["rsync" "-rtv" "--partial"]
   ;(if list ["--from0" (string "--include-from=" list) "--exclude=*"] [])
   ;(if prune ["--delete" "--delete-excluded"] [])
   ;(if exec ["-E"] [])
   ;(if (and (remote? p) (p :ssh))
      ["-e" (string/join ["ssh" ;(p :ssh)] " ")]
      [])
   ;(get p :rsync [])
   src dest])

(defn roms->plan
  ``Group ROMS (as /api/roms returns them) by platform into one rsync each:
  {:plan [{:slug :folder :src :dest :files}] :unmapped {slug [names]}}. A
  multi-file ROM is a directory on disk and is taken whole.``
  [p roms]
  (def dirs (get-in p [:roms :dirs] {}))
  (def by-slug @{})
  (def unmapped @{})
  (each rom roms
    (def slug (rom :platform_fs_slug))
    (def name (string (rom :fs_name) (if (rom :multi) "/" "")))
    (def bucket (if (dirs slug) by-slug unmapped))
    (array/push (or (bucket slug) (get (put bucket slug @[]) slug)) name))
  {:plan (seq [slug :in (sorted (keys by-slug))]
           {:slug slug
            :folder (dirs slug)
            :src (string *library* "/" slug "/roms/")
            :dest (dest p (path/join (get-in p [:roms :root]) (dirs slug)))
            :files (sorted (by-slug slug))})
   :unmapped (tabseq [[k v] :pairs unmapped] k (sorted v))})

(defn firmware->plan
  ``One rsync for a platform's firmware, SLUG/bios/ on the NAS into the
  device's bios dir for it. Nil when the profile has no :platform bios leg.``
  [p firmware slug]
  (when (= :platform (get-in p [:bios :from]))
    (def folder (or (get-in p [:bios :dirs slug])
                    (nextui/tag (get-in p [:roms :dirs slug] slug))))
    {:slug slug
     :folder folder
     :src (string *library* "/" slug "/bios/")
     :dest (dest p (path/join (get-in p [:bios :root]) folder))
     :files (sorted (map |($0 :file_name) firmware))}))

(defn apps->plan
  ``One rsync per engine the profile's :apps names, SLUG/bios/FROM/ on the
  NAS (just FILES of it, if named) into TO on the device, and only for
  platforms the collection has.``
  [p roms]
  (def apps (get p :apps {}))
  (def slugs (distinct (map |($0 :platform_fs_slug) roms)))
  (seq [slug :in (sorted (keys apps)) :when (index-of slug slugs)
        :let [{:from from :to to :files files} (apps slug)]]
    {:slug slug
     :folder to
     :files files
     :src (string *library* "/" slug "/bios/" from "/")
     :dest (dest p to)}))

(defn- urlencode [s]
  (string/join
   (seq [b :in (string/bytes s)]
     (if (or (<= 48 b 57) (<= 65 b 90) (<= 97 b 122) (index-of b [45 46 95 126]))
       (string/from-bytes b)
       (string/format "%%%02X" b)))
   ""))

(defn api/url [path &opt query]
  (string (url-base) path
          (if (and query (not (empty? query)))
            (string "?" (string/join (seq [k :in (sorted (keys query)) :let [v (query k)] :when (not (nil? v))]
                                       (string (urlencode (string k)) "=" (urlencode (string v))))
                                     "&"))
            "")))

(defn parse-sha1sum "sha1sum's output as {file hash}." [text]
  (tabseq [line :in (string/split "\n" (string/trim text))
           :when (not (empty? line))
           :let [[hash file] (peg/match '(* (<- (some :h)) (some " ") (<- (any 1))) line)]]
    file hash))

# RomM's timestamps are ISO 8601, in UTC, to the microsecond. Only the seconds
# matter here; a clock that disagrees by less than that isn't my problem.
(defn iso->time [s]
  (when-let [[Y M D h m sec] (peg/match '(* (number :d+) "-" (number :d+) "-" (number :d+)
                                             (set "T ") (number :d+) ":" (number :d+) ":" (number :d+))
                                        (string s))]
    (os/mktime {:year Y :month (dec M) :month-day (dec D) :hours h :minutes m :seconds sec})))

(defn time->iso [t]
  (let [d (os/date t)]
    (string/format "%04d-%02d-%02dT%02d:%02d:%02dZ"
                   (d :year) (inc (d :month)) (inc (d :month-day))
                   (d :hours) (d :minutes) (d :seconds))))

(defn saves/index
  ``Save files are named for the ROM, so a basename without its extension finds
  the ROM. Two ROMs with the same basename across platforms map to :ambiguous,
  which is reported rather than guessed at.``
  [roms]
  (def index @{})
  (each rom roms
    (def key (path/no-ext (rom :fs_name)))
    (put index key (if (index key) :ambiguous rom)))
  index)

(defn- save-entry [relpath info rom &opt save-id]
  {:operation_id relpath
   :rom_id (rom :id)
   :save_id save-id
   :filename (path/basename relpath)
   :sha1 (info :sha1)
   :file_size (info :size)
   :updated_at (time->iso (info :mtime))})

(defn saves/diff
  ``What changed on the device since the MANIFEST (relpath -> {:sha1 :size
  :mtime :rom_id :save_id}) was written, against a fresh SCAN of the same
  shape, resolved to ROMs through INDEX. The operation id is the relative
  path, so the reply's op_id tells me which file it meant.``
  [manifest scan index]
  (def out @{:created @[] :modified @[] :deleted @[] :unmatched @[]})
  (each relpath (sorted (keys scan))
    (def info (scan relpath))
    (def old (manifest relpath))
    (def rom (index (path/no-ext (path/basename relpath))))
    (cond
      (or (nil? rom) (= rom :ambiguous)) (array/push (out :unmatched) relpath)
      (nil? old) (array/push (out :created) (save-entry relpath info rom))
      (not= (old :sha1) (info :sha1)) (array/push (out :modified) (save-entry relpath info rom (old :save_id)))))
  (each relpath (sorted (keys manifest))
    (unless (scan relpath)
      (def old (manifest relpath))
      (array/push (out :deleted)
                  {:operation_id relpath :rom_id (old :rom_id) :save_id (old :save_id)
                   :filename (path/basename relpath)})))
  out)

(defn saves/client-state
  ``The body of POST /api/sync/negotiate.``
  [device-id last-sync diff now emulator]
  {:device_id device-id
   :device_time (time->iso now)
   :emulators [emulator]
   :restore_unlisted false
   :client_state {:last_sync_time (if last-sync (time->iso last-sync))
                  :saves {:created (diff :created)
                          :modified (diff :modified)
                          :deleted (diff :deleted)}}})


## Runners

(defn reachable?
  ``Cheap: a mount is a directory, a host answers ssh without a prompt.``
  [p]
  (cond (nil? (p :target)) true
        (not (remote? p)) (path/directory? (p :target))
        (sh/$? ssh -o BatchMode=yes -o ConnectTimeout=3 ,;(get p :ssh []) ,(ssh-target p) true
               > :null > [stderr :null])))

(defn check! [p]
  (unless (reachable? p)
    (abort "Can't reach %s (%s)" (p :name) (or (p :target) "localhost"))))

(def- *auth*
  # curl -K reads "user = U:P" off stdin, so the password is never on an argv.
  (delay (let [e (rbw/entry *entry*)]
           (string/format "user = %q\n" (string (get-in e [:data :username]) ":" (get-in e [:data :password]))))))

(defn- curl [& args]
  (def out @"")
  (def err @"")
  (def auth (*auth*))
  (if (sh/$? curl -sS -f -K - ,;args < ,auth > ,out > [stderr err])
    (string out)
    (abort "curl failed: %s" (string/trim err))))

(defn api/get [path &opt query]
  (json/decode (curl (api/url path query)) true))

(defn api/post!
  ``POST (or METHOD) a JSON BODY, or a multipart FORM ({field file-path}).
  Nothing is sent in dry-run; the caller gets nil and carries on.``
  [path &named query body form method]
  (default method "POST")
  (def url (api/url path query))
  (if (dryrun?)
    (do (echof :y "DRYRUN: curl -X %s %s%s" method url
               (cond body (string " " (json/encode body))
                     form (string " -F " (string/join (seq [[k v] :pairs form] (string k "=@" v)) " -F "))
                     ""))
        nil)
    (let [args (cond body ["-H" "Content-Type: application/json" "--data-binary" (json/encode body)]
                     form (catseq [[k v] :pairs form] ["-F" (string k "=@" v)])
                     [])
          out (curl "-X" method ;args url)]
      (if (empty? (string/trim out)) nil (json/decode out true)))))

(defn api/download! [url file]
  (def url (if (string/has-prefix? "/" url) (string (url-base) url) url))
  (if (dryrun?)
    (echof :y "DRYRUN: curl -o %s %s" file url)
    (do (fs/create-dirs (path/dirname file))
        (curl "-o" file url))))

(defn collection-id [p]
  (def name (p :collection))
  (def cols (api/get "/api/collections"))
  (if-let [c (find |(= ($0 :name) name) (if (dictionary? cols) (cols :items) cols))]
    (c :id)
    (abort "No collection named %q on RomM; make one and put %s's games in it" name (p :name))))

(defn collection-roms
  ``Every ROM in the device's collection. /api/roms pages; I walk it until a
  page comes back short.``
  [p]
  (def id (collection-id p))
  (def limit 100)
  (def roms @[])
  (forever
    (def page (api/get "/api/roms" {:collection_id id :limit limit :offset (length roms)}))
    (def items (if (dictionary? page) (page :items) page))
    (array/concat roms items)
    (when (< (length items) limit) (break)))
  roms)

(defn firmware [platform-id]
  (api/get "/api/firmware" {:platform_id platform-id}))

(def- *store* (delay (vars/new (path :data "romm"))))
(defn store [] (*store*))
(defn- key [p & parts] (keyword (string/join [(p :name) ;parts] ".")))

(defn device-id [p] (:get (store) (key p "device")))

(defn register!
  ``Tell RomM this device exists, once. The id it hands back is what every
  negotiate is attributed to.``
  [p]
  (or (device-id p)
      (let [r (api/post! "/api/devices"
                         :body {:device_name (p :name) :platform "linux" :sync_mode "api"
                                :capabilities {}})]
        (when-let [id (get r :id)]
          (:set (store) (key p "device") id)
          id))))

(defn- rules-file [p slug files]
  (def dir (path :runtime "romm"))
  (fs/create-dirs dir)
  (def file (path/join dir (string (p :name) "-" slug ".list")))
  # Written in dry-run too: the printed rsync should be runnable as shown.
  (spit file (include-rules files))
  file)

(defn- run-rsync! [argv]
  (if (do? sh/$? ,;argv) true (do (echof :error "rsync failed: %s" (last argv)) false)))

(defn mkdir! [p path]
  (def abs (resolve-path p path))
  (if (remote? p)
    (do? sh/$? ssh ,;(get p :ssh []) ,(ssh-target p) mkdir -p ,(shell-quote abs))
    (do? sh/$? mkdir -p ,abs)))

(defn sync-roms!
  ``The ROM leg: one rsync per platform in the collection. Returns false if any
  failed. Unmapped platforms are named and skipped, never guessed.``
  [p roms &named prune]
  (unless (path/directory? *library*)
    (abort "The library isn't mounted at %s" *library*))
  (def {:plan plan :unmapped unmapped} (roms->plan p roms))
  (each [slug names] (pairs unmapped)
    (echof :warn "%s: no folder for platform %s (%d ROMs), skipping" (p :name) slug (length names)))
  (var ok true)
  (each {:slug slug :src src :dest dest :files files} plan
    (echof :g "%s -> %s (%d)" slug dest (length files))
    (mkdir! p (path/join (get-in p [:roms :root]) (get-in p [:roms :dirs slug])))
    (unless (run-rsync! (rsync-argv p src dest :list (rules-file p slug files) :prune prune))
      (set ok false)))
  ok)

(defn sync-bios!
  ``:flat mirrors the NAS's _bios/ whole, without --delete, because emulators
  write there too. :platform asks RomM what firmware each platform has and
  moves just that.``
  [p roms]
  (case (get-in p [:bios :from])
    :flat
    (do (mkdir! p (get-in p [:bios :root]))
        (run-rsync! (rsync-argv p (string *library* "/_bios/") (dest p (get-in p [:bios :root])))))
    :platform
    (let [platforms (distinct (map |[($0 :platform_id) ($0 :platform_fs_slug)] roms))]
      (var ok true)
      (each [id slug] platforms
        (def fw (firmware->plan p (firmware id) slug))
        (when (and fw (not (empty? (fw :files))))
          (echof :g "bios %s -> %s (%d)" slug (fw :dest) (length (fw :files)))
          (mkdir! p (path/join (get-in p [:bios :root]) (fw :folder)))
          (unless (run-rsync! (rsync-argv p (fw :src) (fw :dest)
                                          :list (rules-file p (string slug "-bios") (fw :files))))
            (set ok false))))
      ok)
    true))

(defn sync-apps!
  ``The engine leg: a platform's bios/ mirrored whole, like :flat bios, but
  with the executable bit kept.``
  [p roms]
  (var ok true)
  (each {:slug slug :folder folder :files files :src src :dest dest} (apps->plan p roms)
    (echof :g "%s -> %s" slug dest)
    (mkdir! p folder)
    (unless (run-rsync! (rsync-argv p src dest :exec true
                                    :list (if files (rules-file p (string slug "-app") files))))
      (set ok false)))
  ok)

(defn- stage [p leg]
  (if (p :target)
    (path :state "romm" (p :name) (string leg))
    (resolve-path p (get-in p [leg :dir]))))

(defn scan-saves
  ``Every file under DIR, keyed by its path relative to DIR, with the sha1 the
  protocol wants. One sha1sum for the lot.``
  [dir]
  (def out @{})
  (when (path/directory? dir)
    (def hashes (parse-sha1sum (sh/$< find ,dir -type f -exec sha1sum "{}" +)))
    (each [file hash] (pairs hashes)
      (def st (os/stat file))
      (put out (string/no-prefix (string dir "/") file)
           @{:sha1 hash :size (st :size) :mtime (st :modified)})))
  out)

(defn- place
  ``Where a save for ROM that the device has never seen goes, relative to the
  save dir. By-core layouts need the core's directory, which I can only guess
  from the platform.``
  [p leg rom filename]
  (case (get-in p [leg :layout])
    :by-core (if-let [core (get-in p [leg :cores (rom :platform_fs_slug)])]
               (path/join core filename))
    filename))

(defn- pull-stage! [p leg dir]
  (when (p :target)
    (fs/create-dirs dir)
    (mkdir! p (get-in p [leg :dir]))
    (run-rsync! (rsync-argv p (dest p (get-in p [leg :dir])) (string dir "/")))))

(defn- push-stage! [p leg dir]
  (when (p :target)
    (run-rsync! (rsync-argv p (string dir "/") (dest p (get-in p [leg :dir])) :prune true))))

(defn sync-saves!
  ``The save leg, through RomM's sync protocol: say what changed here since
  last time, do what the server says, remember where that left things. The
  device's save dir is staged locally first, so hashing and the manifest never
  run anywhere but here.``
  [p roms]
  (def leg (p :saves))
  (def dir (stage p :saves))
  (def st (store))
  (def by-rom (tabseq [r :in roms] (r :id) r))
  (pull-stage! p :saves dir)
  (def manifest (:get st (key p "saves") @{}))
  (def scan (scan-saves dir))
  (def diff (saves/diff manifest scan (saves/index roms)))
  (each f (diff :unmatched)
    (echof :warn "%s: no ROM in the collection for save %s" (p :name) f))
  (def device (or (register! p) (if (dryrun?) "DRYRUN" (abort "RomM didn't hand back a device id"))))
  (def reply (api/post! "/api/sync/negotiate"
                        :body (saves/client-state device (:get st (key p "last-sync"))
                                                  diff (os/time) (leg :emulator))))
  (def ops (get reply :operations {}))
  (def relpath-of
    # The op echoes my operation id, which is the relative path. A download
    # of something new has none; it gets placed by platform.
    (fn [op]
      (or (op :op_id) (op :operation_id)
          (when-let [rom (by-rom (op :rom_id))]
            (place p :saves rom (op :filename))))))
  (each op (get ops :upload [])
    (when-let [rel (relpath-of op)]
      (echof :g "up   %s" rel)
      (def r (api/post! (or (op :url) "/api/saves")
                        :query (unless (op :url) {:rom_id (op :rom_id) :emulator (leg :emulator)
                                                  :content_hash (get-in scan [rel :sha1])})
                        :form {:saveFile (path/join dir rel)}))
      (when-let [id (get r :id)] (put (scan rel) :save_id id))))
  (each op (get ops :download [])
    (if-let [rel (relpath-of op)]
      (do (echof :g "down %s" rel)
          (api/download! (or (op :url) (op :download_path)) (path/join dir rel)))
      (echof :warn "%s: nowhere to put %s (no core directory for its platform)" (p :name) (op :filename))))
  (each op (get ops :delete [])
    (when-let [rel (relpath-of op)]
      (echof :y "rm   %s" rel)
      (do? sh/$? rm -f ,(path/join dir rel))))
  (when-let [session (get reply :sync_session_id)]
    (api/post! (string "/api/sync/sessions/" session "/complete")))
  (push-stage! p :saves dir)
  (unless (dryrun?)
    (def final (scan-saves dir))
    (each [rel info] (pairs final)
      (def rom (get (saves/index roms) (path/no-ext (path/basename rel))))
      (put info :rom_id (if (table? rom) (rom :id)))
      (put info :save_id (or (get-in scan [rel :save_id]) (get-in manifest [rel :save_id]))))
    (:set st (key p "saves") final)
    (:set st (key p "last-sync") (os/time)))
  true)

(defn sync-states!
  ``States aren't in the sync protocol, so this is the dumb version: per ROM,
  the newer of the device's state and RomM's wins, by timestamp.``
  [p roms]
  (def leg (p :states))
  (def dir (stage p :states))
  (def index (saves/index roms))
  (pull-stage! p :states dir)
  (def local (scan-saves dir))
  (def seen @{})
  (each [rel info] (pairs local)
    (def rom (index (path/no-ext (path/basename rel))))
    (when (table? rom)
      (put seen (rom :id) true)
      (def remote (find |(= ($0 :file_name) (path/basename rel))
                        (or (api/get "/api/states" {:rom_id (rom :id)}) [])))
      (def rtime (if remote (iso->time (remote :updated_at)) 0))
      (cond
        (> (info :mtime) rtime)
        (do (echof :g "up   %s" rel)
            (if remote
              (api/post! (string "/api/states/" (remote :id)) :method "PUT" :form {:stateFile (path/join dir rel)})
              (api/post! "/api/states" :query {:rom_id (rom :id) :emulator (leg :emulator)}
                         :form {:stateFile (path/join dir rel)})))
        (< (info :mtime) rtime)
        (do (echof :g "down %s" rel)
            (api/download! (remote :download_path) (path/join dir rel))))))
  # States RomM has for ROMs the device has never saved a state for.
  (each rom roms
    (unless (seen (rom :id))
      (each remote (or (api/get "/api/states" {:rom_id (rom :id)}) [])
        (if-let [rel (place p :states rom (remote :file_name))]
          (do (echof :g "down %s" rel)
              (api/download! (remote :download_path) (path/join dir rel)))))))
  (push-stage! p :states dir)
  true)

(defn status [p]
  (def st (store))
  {:device (p :name)
   :target (or (p :target) "localhost")
   :reachable (reachable? p)
   :registered (device-id p)
   :last-sync (if-let [t (:get st (key p "last-sync"))] (time->iso t))
   :legs (filter |(get p $0) [:roms :bios :apps :saves :states])})
