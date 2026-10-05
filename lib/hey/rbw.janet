# lib/hey/rbw.janet

(use ./.)

(defn- wayland-display []
  # rbw hands WAYLAND_DISPLAY to pinentry(-rofi), but a relative one resolves
  # against $XDG_RUNTIME_DIR, which I may have pointed somewhere else.
  (when-let [wl (os/getenv "WAYLAND_DISPLAY")]
    (if (path/abspath? wl) wl (path/xdg :runtime wl))))

(defn with-vault*
  ``Call F with rbw talking to an agent of its own, and kill that agent after.
  Unlocking is left to rbw: the first command that needs the vault prompts.``
  [f]
  (os/mkdir (path :runtime))
  # rbw keeps its socket and pidfile in $XDG_RUNTIME_DIR/rbw, and everything
  # worth keeping (db, config) elsewhere, so a private runtime dir is a private
  # agent that's still logged in.
  (def dir (sh/$<_ mktemp -d -p ,(path :runtime) rbw.XXXXXX))
  (var stopped? false)
  (defn stop [&]
    (unless stopped?
      (set stopped? true)
      (with-envvars ["XDG_RUNTIME_DIR" dir]
        (sh/$? rbw stop-agent > :null > [stderr :null]))
      (sh/$? rm -rf ,dir)))
  (trap stop)  # defer doesn't survive a SIGINT (see init.janet)
  (defer (stop)
    (with-envvars ["XDG_RUNTIME_DIR" dir
                   "WAYLAND_DISPLAY" (wayland-display)]
      (f))))

(defmacro with-vault [& body]
  ~(,with-vault* (fn [] ,;body)))


## The session agent

# What rbw list --raw calls them; I'd rather dispatch on a keyword.
(def- types {"Login" :login "Card" :card "Identity" :identity
             "Note" :note "SSH Key" :sshkey})

(defn unlocked? []
  (sh/$? rbw unlocked > :null > [stderr :null]))

(defn unlock []
  (sh/$? rbw unlock))

(defn lock []
  (sh/$? rbw lock))

(defn config []
  (json/decode (sh/$<_ rbw config show) true))

(defn type-of
  ``:login/:card/:identity/:sshkey/:note.``
  [entry]
  (def data (get entry :data {}))
  (cond (has-key? data :password)    :login
        (has-key? data :number)      :card
        (has-key? data :first_name)  :identity
        (has-key? data :private_key) :sshkey
        :note))

(defn items []
  (seq [it :in (json/decode (sh/$<_ rbw list --raw) true)]
    (put it :type (get types (it :type) :unknown))))

(defn entry [id]
  (def e (json/decode (sh/$<_ rbw get --raw ,id) true))
  (put e :type (type-of e)))

(defn code [id]
  (def out @"")
  (when (sh/$? rbw code ,id > ,out > [stderr :null])
    (string/trimr out)))


## Generators. rbw has the EFF list and a CSPRNG; I only do the formatting.

(defn generate [len & flags]
  (sh/$<_ rbw generate ,;flags ,(string len)))

(defn- rng [] (math/rng (os/cryptorand 8)))

(defn- capitalize [word]
  (string (string/ascii-upper (string/slice word 0 1)) (string/slice word 1)))

(defn format-passphrase
  "WORDS capitalized and dash-joined, DIGIT tacked onto the IDX'th."
  [words idx digit]
  (string/join (seq [[i w] :pairs words]
                 (string (capitalize w) (if (= i idx) digit "")))
               "-"))

(defn password []
  (generate 32 "--no-symbols"))

(defn passphrase [&opt n]
  (default n 5)
  (def words (string/split " " (generate n "--diceware")))
  (def r (rng))
  (format-passphrase words (math/rng-int r (length words)) (math/rng-int r 10)))

(defn username []
  (string (capitalize (generate 1 "--diceware"))
          (fmt "%04d" (math/rng-int (rng) 10000))))

(defn email [domain]
  (string (string/ascii-lower (generate 8 "--no-symbols")) "@" domain))
