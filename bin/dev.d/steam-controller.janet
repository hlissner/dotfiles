#!/usr/bin/env janet
# Power Steam Controllers off, without Steam.
#
# SYNOPSIS:
#   hey .dev steam-controller off
#
# DESCRIPTION:
#   Steam+Y only turns the controller off while Steam is running (doing nothing
#   otherwise), so the only option is to wait for the controller to turn itself
#   off. I hate this, so I wrote this scritp to turn off the controller (and
#   wrap Steam in modules/games/steam.nix to call it when Steam exits).
#
# ARGUMENTS:
#   1 COMMAND
#     off -- Turn connected controllers off.

(use hey)

# Wired, BLE, the Puck, the Steam Machine's receiver; over USB or Bluetooth.
(def- valve '(* "000" (set "35") ":000028DE:0000130" (range "25")))

# Feature report 1, 63 bytes: the collection commands go to.
(def- commands "8501953f0901b102")

(def- off-frame
  (let [b @"\x01\x9f\x04off!"]
    (buffer/push b (string/repeat "\0" (- 64 (length b))))))

# HIDIOCSFEATURE(64): _IOC(read|write, 'H', 6, 64)
(def- HIDIOCSFEATURE 0xC0404806)
(def- O_RDWR 2)

(def- libc (delay (ffi/native)))

(defn- libc-fn [name & sig]
  (def ptr (or (ffi/lookup (libc) name) (abort "No %s in libc" name)))
  (def sig (ffi/signature :default ;sig))
  (fn [& args] (ffi/call ptr sig ;args)))

(defn- sysfs [name & parts]
  (string "/sys/class/hidraw/" name "/device/" ;parts))

(defn- hid-id [name]
  (-?> (peg/match '(any (+ (* "HID_ID=" (<- (any 1))) (* (thru "\n"))))
                  (string (slurp (sysfs name "uevent"))))
       (first)))

(defn- hex [bytes]
  (string/join (map |(string/format "%02x" $0) bytes)))

(defn- slot? [name]
  (and (peg/match valve (or (ignore-errors (hid-id name)) ""))
       (string/find commands (hex (slurp (sysfs name "report_descriptor"))))))

(defn- slots []
  (seq [name :in (sorted (or (ignore-errors (os/dir "/sys/class/hidraw")) []))
        :when (ignore-errors (slot? name))]
    (string "/dev/" name)))

(defn- send-feature [node frame]
  (def open (libc-fn "open" :int :string :int))
  (def ioctl (libc-fn "ioctl" :int :int :uint64 :ptr))
  (def close (libc-fn "close" :int :int))
  (def strerror (libc-fn "strerror" :string :int))
  (defn errno [] (strerror (ffi/read :int (ffi/call (ffi/lookup (libc) "__errno_location")
                                                    (ffi/signature :default :ptr)))))
  (def fd (open node O_RDWR))
  (when (< fd 0) (error (errno)))
  (defer (close fd)
    (when (< (ioctl fd HIDIOCSFEATURE frame) 0)
      (error (errno)))))

(defmain [_ command]
  (unless (= command "off") (usage))
  (def nodes (slots))
  (when (empty? nodes) (log "No Steam Controller interfaces") (exit 0))
  (each node nodes
    (if (dryrun?)
      (echo :y (string/format "would send %s to %s" (hex (slice off-frame 0 7)) node))
      (match (protect (send-feature node off-frame))
        [true _] (log "%s: off" node)
        [false err] (log "%s: %s" node err)))))
