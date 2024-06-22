#!/usr/bin/env janet
# Manage and insert from bitwarden.
#
# SYNOPSIS:
#   vaultmenu
#
# DESCRIPTION:
#   TODO

(use hey)
(use hey/cmd)
(import hey/rofi)
(import hey/vars)
(import hey/sys)

(def- *vars* (vars/new (:dir vars/temp :rofi :vaultmenu)))
(def- *webvault-url* "https://vault.home.lissner.net")
(def- *data-dir* (path :runtime "vaultwarden.d"))
(os/mkdir *data-dir*)

(defmacro- bw [& args]
  (tuple '$<_ 'bw '--nointeraction '--session '(unquote (session-key))
         ;args))

(defmacro- bw? [& args]
  (tuple '$? 'bw '--nointeraction '--session '(unquote (session-key))
         ;args))

(defn- session-key [&opt reload?]
  (:cache *vars* :sesskey
    |(if-let [p (rofi/read :password true
                           :placeholder "Enter master password..."
                           :message "Vault is locked."
                           :icon "lock")]
       (let [pfile (path :runtime "vaultmenu.tmp")]
         (defer (os/rm pfile)
           (spit pfile p)
           ($<_ bw unlock --nointeraction --passwordfile ,pfile --raw)))
       (abort "Aborted"))
    reload?))

(defn- unlock! []
  (unless (bw? unlock --check)
    (:set *vars* :sesskey nil)))

(defn- items [&opt reload?]
  (:cache *vars* :items |(json/decode (bw list items) :keywords true)
          reload?))

(defn do-copy [item field str &opt secret?]
  (when (sys/yank str :once secret?)
    (sys/notify (fmt "From: '%s'" (item :name))
                :title (fmt "Copied '%s' to clipboard" field)
                :icon "clipboard"
                :sound "notify")))

(defn do-copy-attachment [item att]
  (let [type (case* (path/ext (att :fileName))
                    ["png" "jpg" "jpeg" "gif" "svg"] "text/uri-list"
                    "text/plain")
        tmpfile (path/join *data-dir* (string "att." (att :fileName)))
        error @""]
    (sys/notify "Fetching attachment..." :urgency "low" :sound "blip")
    (unlock!)
    (defer (ignore-errors (os/rm tmpfile))
      (if (bw? get attachment ,(att :id) --itemid ,(item :id) --output ,tmpfile > [stderr error])
        (do
          (sys/yank-file tmpfile type)
          (sys/notify (fmt "From: '%s'" (item :name))
                      :title (fmt "Copied attachment '%s' to clipboard" (att :fileName))
                      :icon "clipboard"
                      :sound "notify"))
        (sys/notify (string error)
                    :title (fmt "Error fetching attachment: %s" (att :fileName))
                    :icon "error"
                    :sound "notify-critical")))))

(defn do-generate [type]
  (sys/notify (fmt "Generating %s..." type) :urgency "low" :sound "blip")
  (when-let [gen (case type
                   :passphrase (bw generate -p -uln --words 5)
                   :username (fmt "%s@login.henrik.io" (bw generate -uln --length 8))
                   (abort "Unknown generator: %s" type))]
    (sys/yank gen)
    (sys/notify gen
                :title (fmt "Copied %s to clipboard" type)
                :icon "clipboard"
                :sound "notify")))


(defn view-item [item]
  (:set *vars* :lastitem (item :id))
  (rofi/chain [rofi
               :theme "vaultmenu"
               :placeholder (fmt "Search %s..."
                                 (case (item :type)
                                   1 "login fields"
                                   2 "note"
                                   3 "card details"
                                   4 "identity"
                                   "entries"))]
    (:add rofi "<b>Open in webvault</b> ->"
          :icon "link"
          :data (fn [] ($ xdg-open ,(fmt "%s/#/vault?itemId=%s" *webvault-url* (item :id)))))
    (when (get-in item [:login :username])
      (:add rofi (fmt "<b>Username:</b> %s" (get-in item [:login :username]))
            :icon "identity"
            :data (fn [] (do-copy item "username" (get-in item [:login :username])))))
    (when (get-in item [:login :password])
      (:add rofi (fmt "<b>Password:</b> %s" (string/repeat "*" (length (get-in item [:login :password]))))
            :icon "lock"
            :data (fn [] (do-copy item "password" (get-in item [:login :password]) true))))
    (when (get-in item [:login :totp])
      (:add rofi "<b>Generate OTP code</b>"
            :icon "clock"
            :data (fn []
                    (unlock!)
                    (do-copy item "OTP code" (bw get totp ,(item :id))))))
    (when (get item :notes)
      (:add rofi (fmt "<b>Notes:</b> %s" (get item :notes))
            :icon "x-shape-text"
            :data (fn [] (do-copy item "notes" (get item :notes)))))
    (each field (get item :fields [])
      (:add rofi (fmt "<b>%s:</b> %s" (field :name)
                      (if (= (field :type) 1)
                        (string/repeat "*" (length (field :value)))
                        (field :value)))
            :icon "text-field"
            :data (fn [] (do-copy item (field :name) (field :value) (= (field :type) 1)))))
    (when (get :item :attachments)
      (:div rofi))
    (each att (get item :attachments [])
      (:add rofi (fmt "<b>Attachment:</b> %s (%s)"
                      (get att :fileName)
                      (get att :sizeName))
            :icon "pin"
            :data (fn [] (do-copy-attachment item att))))))

(def- *deleted-fid* "d7717d3d-95a2-4adf-9afe-869f808455da")
(defn list-items [&opt reload?]
  (let [items (items reload?)]
    (rofi/chain [rofi :theme "vaultmenu"]
      (:add rofi "Open Webvault"
            :icon "reload"
            :data (fn [] ($ xdg-open ,*webvault-url*)))
      (:add rofi "Sync Vault"
            :icon "reload"
            :data (fn [] (list-items true)))
      (:add rofi "Generate a username"
            :icon "username-copy"
            :data (fn [] (do-generate :username)))
      (:add rofi "Generate a passphrase"
            :icon "password-copy"
            :data (fn [] (do-generate :passphrase)))
      (:div rofi)
      (each item items
        (unless (= (item :folderId) *deleted-fid*)
          (:add rofi (fmt "<b>%s</b> %s <span size='small' alpha='50%%'>%s</span>"
                          (case (item :type)
                            1 "Login:"
                            2 "Note:"
                            3 "Card:"
                            4 "Identity:"
                            "Unknown:")
                          (get item :name "")
                          (get-in item [:login :username] ""))
                # TODO: Favicon lib
                :icon (case (item :type)
                        1 "lock"
                        2 "x-shape-text"
                        3 "account-types-credit-card"
                        4 "identity"
                        "<span color='white'>?</span>")
                :data (fn [] (view-item item))))))))

(defmain [_ & args &opts reload? -r resume? -l]
  (when resume?
    (when-let [items (items reload?)
               id (:get *vars* :lastitem)]
      (if-let [item (find |(= (get $ :id) id) items)]
        (do (view-item item)
            (exit 0))
        (echo "No item to resume. Starting from scratch..."))))
  (list-items reload?))
