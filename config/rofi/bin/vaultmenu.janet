#!/usr/bin/env janet
# A read-only rofi interface for vaultwarden (through rbw).
#
# SYNOPSIS:
#   vaultmenu [-r|--resume]
#
# OPTIONS:
#   -r, --resume
#     Reopen the screen (and entry) that was showing when it last closed.

(use hey)
(use sh)
(import hey/rbw)
(import hey/rofi)
(import hey/sys)
(import hey/vars)

(def- *domain* "login.henrik.io")
(def- *theme* "vaultmenu.rasi")
(def- *stars* (string/repeat "*" 8))
(def- *vars* (vars/new (:dir (vars/temp) :rofi :vaultmenu)))

(def- *types*
  {:login    ["Login Item"  "1password-panel"]
   :card     ["Card"        "account-types-credit-card"]
   :identity ["Identity"    "user-identity-symbolic"]
   :note     ["Secure Note" "notes-panel"]
   :sshkey   ["SSH Key"     "cm_runterm"]
   :unknown  ["Item"        "text-x-generic-symbolic"]})

(defn- type-info [type]
  (get *types* type (*types* :unknown)))

(defn- val [v]
  (unless (or (nil? v) (= v :null) (= v "")) v))

(defn- oneline [s]
  (def flat (string/replace-all "\n" " " (string/trim s)))
  (if (> (length flat) 60) (string (string/slice flat 0 59) "…") flat))

(defn- remember [& screen]
  (:set *vars* :screen screen))

(defn- enter [screen & args]
  (fn [] (let [r (screen ;args)] (if (= r :back) :restart r))))


## Clipboard

(defn- copy! [what value &named secret]
  (if (sys/yank value :sensitive secret)
    (sys/notify what :title "Copied to clipboard" :icon "edit-copy-symbolic" :sound "blip")
    (sys/notify (fmt "Couldn't copy %s" what) :urgency "critical" :icon "dialog-error-symbolic"))
  :copied)

(defn- open-url [url]
  (os/spawn ["xdg-open" url] :pd)
  :opened)

(defn- vault-url [id]
  (def cfg (rbw/config))
  (string (string/trimr (or (val (cfg :ui_url)) (val (cfg :base_url)) "https://vault.bitwarden.com") "/")
          "/#/vault?itemId=" id))


## The main list

(defn- meta [item entry]
  (def d (get entry :data {}))
  (defn join [sep & parts] (val (string/join (filter truthy? (map val parts)) sep)))
  (case (item :type)
    :login (val (item :user))
    :card (join ", " (d :brand)
                (when-let [n (val (d :number))]
                  (string "*" (string/slice n (max 0 (- (length n) 4))))))
    :identity (join " " (d :title) (d :first_name) (d :middle_name) (d :last_name))))

(defn- fetch-items []
  (seq [it :in (rbw/items)]
    {:id (it :id)
     :type (it :type)
     :name (or (val (it :name)) "(unnamed)")
     # Only cards and identities need a decrypt to describe
     :meta (meta it (when (index-of (it :type) [:card :identity])
                      (rbw/entry (it :id))))}))

(defn- items [&opt reload?]
  (:cache *vars* :items fetch-items reload?))

(defn- label [item]
  (fmt "<span alpha='50%%'><b>%s:</b></span> %s%s"
       (first (type-info (item :type)))
       (rofi/escape (item :name))
       (if-let [m (item :meta)]
         (fmt " <span alpha='50%%' size='x-small'>%s</span>" (rofi/escape m))
         "")))


## One entry

(defn- field-rows
  "[LABEL VALUE HIDE? ICON] for every field of ENTRY worth a row, typed ones first."
  [entry]
  (def d (get entry :data {}))
  (def typed
    (case (entry :type)
      :login [["Username" (d :username) false "avatar-default-symbolic"]
              ["Password" (d :password) true "dialog-password-symbolic"]]
      :card [["Cardholder" (d :cardholder_name) false "avatar-default-symbolic"]
             ["Brand" (d :brand) false "secure-card-symbolic"]
             ["Number" (d :number) true "secure-card-symbolic"]
             ["Expires" (when (and (val (d :exp_month)) (val (d :exp_year)))
                          (fmt "%s/%s" (d :exp_month) (d :exp_year)))
              false "clock-symbolic"]
             ["Code" (d :code) true "changes-prevent-symbolic"]]
      :identity [["Title" (d :title) false "user-identity-symbolic"]
                 ["First name" (d :first_name) false "user-identity-symbolic"]
                 ["Middle name" (d :middle_name) false "user-identity-symbolic"]
                 ["Last name" (d :last_name) false "user-identity-symbolic"]
                 ["Username" (d :username) false "avatar-default-symbolic"]
                 ["Email" (d :email) false "mail-message-new-symbolic"]
                 ["Phone" (d :phone) false "phone-symbolic"]
                 ["Address 1" (d :address1) false "mark-location-symbolic"]
                 ["Address 2" (d :address2) false "mark-location-symbolic"]
                 ["Address 3" (d :address3) false "mark-location-symbolic"]
                 ["City" (d :city) false "mark-location-symbolic"]
                 ["State" (d :state) false "mark-location-symbolic"]
                 ["Postal code" (d :postal_code) false "mark-location-symbolic"]
                 ["Country" (d :country) false "mark-location-symbolic"]
                 ["SSN" (d :ssn) true "changes-prevent-symbolic"]
                 ["License number" (d :license_number) true "changes-prevent-symbolic"]
                 ["Passport number" (d :passport_number) true "changes-prevent-symbolic"]]
      :sshkey [["Public key" (d :public_key) false "utilities-terminal-symbolic"]
               ["Fingerprint" (d :fingerprint) false "auth-fingerprint-symbolic"]
               ["Private key" (d :private_key) true "changes-prevent-symbolic"]]
      []))
  (def custom
    (seq [f :in (get entry :fields [])
          :let [name (or (val (f :name)) "Field")
                value (val (f :value))]
          :when value]
      (case (f :type)
        "hidden" [name value true "changes-prevent-symbolic"]
        "boolean" [name value false (if (= value "true")
                                      "checkbox-checked-symbolic"
                                      "checkbox-symbolic")]
        "linked" nil
        [name value false "text-x-generic-symbolic"])))
  (filter |(and $0 (val ($0 1))) [;typed ;custom]))

(defn- entry-screen [item]
  (remember :entry (item :id))
  (def e (rbw/entry (item :id)))
  (def name (item :name))
  (def notes (val (e :notes)))
  (def uri (-?> (get-in e [:data :uris]) val first (get :uri) val))
  (rofi/chain [r :theme *theme* :prompt name
               :message (when notes (rofi/escape notes))]
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:add r "<b>Open in Vault</b> ->" :icon "security-high-symbolic"
          :data (fn [] (open-url (vault-url (item :id)))))
    (when uri
      (:add r (fmt "<b>Open URL</b> <span alpha='50%%'>(%s)</span> ->" (rofi/escape (oneline uri)))
            :icon "web-browser-symbolic" :data (fn [] (open-url uri))))
    (:div r)
    (defn add-row [[label value hide? icon]]
      (:add r (fmt "<span alpha='50%%'><b>%s:</b></span> %s" (rofi/escape label)
                   (if hide? *stars* (rofi/escape (oneline value))))
            :icon icon
            :data (fn [] (copy! (fmt "%s of %s" label name) value :secret true))))
    (def rows (field-rows e))
    (if (not= (e :type) :login)
      (each row rows (add-row row))
      # Username, password, TOTP (if it has one), then the rest.
      (do (each row (slice rows 0 2) (add-row row))
          (when (val (get-in e [:data :totp]))
            (:add r "<b>Copy TOTP Code</b>" :icon "clock-symbolic"
                  :data (fn []
                          (if-let [c (rbw/code (item :id))]
                            (copy! (fmt "TOTP code of %s" name) c :secret true)
                            (do (sys/notify (fmt "Couldn't get a TOTP code for %s" name)
                                            :urgency "critical" :icon "clock-symbolic")
                                :restart)))))
          (each row (slice rows 2) (add-row row))))))


## Generators

(defn- generate-screen []
  (remember :generate)
  (rofi/chain [r :theme *theme* :prompt "Generate"]
    (defn row [label hint icon make &named secret]
      (:add r (fmt "<b>%s</b> <span alpha='50%%' size='x-small'>%s</span>" label hint)
            :icon icon
            :data (fn [] (let [v (make)]
                           # Only the secrets stay out of the toast.
                           (copy! (if secret
                                    (fmt "Generated %s" (string/ascii-lower label))
                                    (fmt "%s: %s" label v))
                                  v :secret secret)))))
    (:add r "<b>Back</b>" :icon "go-previous-symbolic" :data :back)
    (:div r)
    (row "<b>Password</b>" "32 characters, no symbols" "dialog-password-symbolic" rbw/password :secret true)
    (row "<b>Passphrase</b>" "5 words, one digit" "accessories-dictionary-symbolic" rbw/passphrase :secret true)
    (row "<b>Email address</b>" (string "@" *domain*) "mail-message-new-symbolic" |(rbw/email *domain*))
    (row "<b>Username</b>" "a word and 4 digits" "user-info-symbolic" rbw/username)))


## Main

(defn- resume []
  (match (:get *vars* :screen)
    [:generate] (generate-screen)
    [:entry id] (if-let [item (find |(= ($0 :id) id) (items))]
                  (entry-screen item)
                  :back)
    :back))

(defmain [_ &opts resume? [-r --resume]]
  (unless (or (rbw/unlocked?) (rbw/unlock))
    (abort "Vault is locked"))
  (def r (if resume? (resume) :back))
  (when (= r :back)
    (remember :main)
    (rofi/chain [r :theme *theme* :prompt "Vault"]
      (:add r "<b>Lock Vault</b>" :icon "system-lock-screen-symbolic"
            :data (fn []
                    (rbw/lock)
                    (:clear *vars*)
                    (sys/notify "Vault locked" :icon "system-lock-screen-symbolic")
                    :locked))
      (:add r "<b>Reload</b>" :icon "view-refresh-symbolic" :data (fn [] (items true) :restart))
      (:add r "<b>Generate</b> ->" :icon "password-generate-symbolic" :data (enter generate-screen))
      (:div r)
      (each item (items)
        (:add r (label item)
              :icon (last (type-info (item :type)))
              :data (enter entry-screen item))))))
