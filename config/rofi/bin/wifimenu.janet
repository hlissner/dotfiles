#!/usr/bin/env janet
# Open a wifi menu.
#
# Manage your wifi connection via Rofi, but unlike all the other Rofi wifi
# scripts out there, this one doesn't depend on NetworkManager! Just good ol'
# wpa_cli and wpa_supplicant (for those networking.useNetworkd fanatics out
# there, like me).
#
# SYNOPSIS:
#   wifimenu [--rescan]

(use hey)
(use hey/cmd)
(import hey/sys)
(import hey/rofi)

(defn- known-networks []
  (map (fn [l]
         (let [[id ssid bssid flags] (string/split "\t" l)]
           {:id id
            :ssid ssid
            :bssid bssid
            :flags flags}))
       (slice (string/split "\n" ($<_ wpa_cli list_networks)) 2)))

(defn- scan-results [&opt rescan?]
  # REVIEW: I'm not using the wpa_supplicant sockets because the Janet net lib
  #   has issues with datagram sockets.
  # TODO: Add lock file
  (when rescan?
    (echo "Rescanning...")
    (with [c (os/spawn ["wpa_cli"] :p {:in :pipe :out :pipe})]
      (ev/write (c :in) "SCAN\n")
      (var buf @"")
      (while (ev/read (c :out) 4096 buf)
        (when (string/find "<3>CTRL-EVENT-SCAN-RESULTS " buf)
          (break))
        (ev/sleep 0.2)
        # TODO: Add timeout
        )))
  (let [ssids @{}
        known (map |(get $ :ssid) (known-networks))
        current (some (fn [line]
                        (let [[_ ssid _ flags] (string/split "\t" line)]
                          (when (string/find "[CURRENT]" flags)
                            ssid)))
                      (slice (string/split "\n" ($<_ wpa_cli list_networks)) 2))]
    (each ssid (slice (string/split "\n" ($<_ wpa_cli scan_results)) 2)
      (var [mac freq sig flags ssid] (string/split "\t" ssid))
      (when ssid
        (set ssid (string/trim (peg/replace-all (peg! '(* "\\x" (between 1 2 :d))) "" ssid)))
        (unless (= ssid "")
          (put ssids ssid
               @{:ssid ssid
                 :mac mac
                 :freq (case (-?> freq (scan-number) (/ 1000) (math/trunc))
                         2 "2.4ghz"
                         5 "5ghz"
                         "???")
                 :sig (or (scan-number sig) -100)
                 :flags flags
                 :known (and (index-of ssid known) true)
                 :current (= current ssid)}))))
    ssids))

(defn- current-ap [&opt results]
  (find (fn [ap] (get ap :current)) (or results (scan-results))))

# TODO
(defn connect [ap]
  (not-implemented :connect ap))

# TODO
(defn disconnect [ap]
  (not-implemented :disconnect ap))

# TODO
(defn connect-direct []
  (not-implemented :connect-direct))

(defn- add-network [rofi ap]
  (let [sig (ap :sig)]
    (:add rofi (fmt "%s %s <span size='small' alpha='50%%'>[%s]%s</span>"
                    (if (ap :current)
                      "<b>Disconnect:</b>"
                      "<b>Connect:</b>")
                    (rofi/escape (ap :ssid))
                    (ap :freq)
                    (ap :flags))
          :icon (cond (> sig -50) "network-wireless-signal-excellent"
                      (> sig -60) "network-wireless-signal-good"
                      (> sig -70) "network-wireless-signal-ok"
                      (> sig -80) "network-wireless-signal-low"
                      "network-wireless-signal-none")
          :data (fn [] (if (ap :current)
                         (disconnect ap)
                         (connect ap))))))

(defn- select-ap [&opt rescan?]
  (rofi/chain [rofi :theme "wifimenu"]
    # TODO: Turn on/off radio
    (:add rofi "<b>Rescan networks</b> <span alpha='40%%'>-></span>"
          :icon "search-symbolic"
          :data (fn [] (select-ap true)))
    (:add rofi (fmt "<b>Connect to SSID directly</b> <span alpha='40%%'>-></span>")
          :icon "text-editor-symbolic"
          :data (fn [] (connect-direct))) # TODO
    (let [results (sort (values (scan-results rescan?))
                        (fn [a b] (> (get a :sig) (get b :sig))))]
      (when-let [ap (current-ap results)]
        (take! 1 results)
        (add-network rofi ap))
      (:div rofi)
      (if (empty? results)
        (:add rofi "<span alpha='40%%'>No networks found...</span>"
              :icon "cross"
              :nonselectable true)
        (each ap results
          (unless (ap :current)
            (add-network rofi ap)))))))

(defmain [_ & args &opts rescan? [-r --rescan]]
  (unless (path/find "wpa_cli")
    (abort "wpa_cli not in your PATH"))
  (select-ap rescan?))
