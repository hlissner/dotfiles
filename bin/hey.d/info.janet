#!/usr/bin/env janet
# Display information about the current system (JSON).
#
# SYNOPSIS:
#   info [-r] [KEYS...]
#   info [-r] ip [-w]
#   info [user/repo|https://url/to/git/repo]
#
# OPTIONS:
#   -r
#     Print raw values instead of JSON.
#   -w
#     Query the WAN address instead of the LAN one.
#
# ARGUMENTS:
#   * KEY @info-keys

(use hey)
(use sh)

(defn- ip [wan? & args]
  (if wan?
    ($<_ dig +short "myip.opendns.com" "@resolver1.opendns.com")
    (get (string/split " " ($<_ ip -o -4 route show to default)) 8)))

(defn- repo [url]
  (do? $ nix-prefetch-git --quiet ,url))

(defcmd info [_ & args &opts raw? -r wan? -w]
  (let [format (if raw? :raw :json)]
    (var cmd (or (first args) ""))
    (cond (= cmd "ip")
          (echo format (ip wan? ;(slice args 1)))

          (peg/match '(* "http" (? "s") "://") cmd)
          (repo cmd)

          (set cmd (peg/match {:seg '(capture (some (+ :w (set "_-.@"))))
                               :main '(* :seg "/" :seg)}
                              cmd))
          (repo (string "https://github.com/" (in cmd 0) "/" (in cmd 1)))

          (echo format (flake/info ;(map keyword args))))))
