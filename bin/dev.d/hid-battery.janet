#!/usr/bin/env janet
# Batteries that are only on the wire, as JSON lines.
#
# SYNOPSIS:
#   hey .dev hid-battery [-t SECONDS]
#   hey .dev hid-battery -w [-i SECONDS]
#
# DESCRIPTION:
#   Reads battery for hidraw devices, one JSON object per line:
#
#     {"event":"battery","node":"/dev/hidraw1","serial":"…","name":"…",
#      "percent":96,"state":"discharging","mv":4121}
#
#   Without -w, every device is asked once: exit 0 with nothing printed when
#   nothing answers, or when there's no such hardware. With -w it keeps going,
#   printing a reading whenever one arrives, plus
#
#     {"event":"gone","node":"/dev/hidraw1"}
#
#   Looks for two kinds of device:
#
#   Valve (28de): the Steam Controller (2026), on its Puck dongle, wired or BLE,
#   volunteers a battery report (ID 0x43) every few seconds; three missed is
#   asleep.
#
#   Compx (260d), the chip in most 2.4GHz mice: a query on the vendor collection
#   (usage page 0xFF02, report 8), answered at once by the interface that owns
#   the mouse -- its twin advertises the same collection and never answers.
#   These nodes are root-only unless udev tags them uaccess (see
#   modules/wm/noctalia.nix).
#
# OPTIONS:
#   -w, --watch
#     Keep running and print events as they happen.
#   -t, --timeout SECONDS
#     Without -w: how long to wait for a Valve report. Default 6.
#   -i, --interval SECONDS
#     With -w: how often to ask Compx devices. Default 30.

(use hey)

# Linux 7.3's hid-steam (hid-ids.h): IBEX wired, IBEX_BLE, PROTEUS (the Puck),
# NEREID (the Steam Machine's receiver). None of my kernels bind hid-steam to
# them yet, and the one that will unregisters its power_supply the moment Steam
# opens the hidraw node, so this does not wait for it.
(def- valve '(* "0003:000028DE:0000130" (range "25")))

(def- compx '(* "0003:0000260D:"))

# Usage page 0xFF02, usage 2, report ID 8: the collection the query goes to.
(def- compx-collection "0602ff0902a1018508")

(def- valve-states {1 "discharging" 2 "charging" 4 "fully-charged"})
(def- compx-states {0 "discharging" 1 "charging" 2 "fully-charged"})

(def- rescan 5)        # seconds between hotplug scans, and ticks
(def- valve-stale 15)  # three missed reports at the firmware's ~4s cadence

(defn- sysfs [name & parts]
  (string "/sys/class/hidraw/" name "/device/" ;parts))

(defn- uevent [name]
  (def out @{})
  (each line (string/split "\n" (string (slurp (sysfs name "uevent"))))
    (if-let [[k v] (peg/match '(* "HID_" (<- (some (range "AZ" "__"))) "=" (<- (any 1))) line)]
      (put out k v)))
  out)

(defn- hex [bytes]
  (string/join (map |(string/format "%02x" $) bytes)))

(defn- kind [name id]
  (cond
    (peg/match valve id) :valve
    (and (peg/match compx id)
         (string/find compx-collection (hex (slurp (sysfs name "report_descriptor")))))
    :compx))

# A node yanked between os/dir and here is nothing to report.
(defn- probe [name]
  (def [ok dev]
    (protect
      (def ev (uevent name))
      (if-let [kind (kind name (get ev "ID" ""))]
        {:kind kind
         :node (string "/dev/" name)
         :name (get ev "NAME" "")
         :serial (get ev "UNIQ" "")})))
  (if ok dev))

(defn- nodes []
  (seq [name :in (or (ignore-errors (os/dir "/sys/class/hidraw")) [])
        :let [dev (probe name)]
        :when dev]
    dev))

# Janet block-buffers stdout into a pipe like everyone else, and the reader
# wants each line as it happens -- the next one may be minutes off.
(defn- emit [event & kvs]
  (print (json/encode (struct :event event ;kvs)))
  (flush))

(defn- emit-battery [dev bat]
  (emit "battery" :node (dev :node) :serial (dev :serial) :name (dev :name) ;(kvs bat)))

(defn- valve-battery [buf]
  (when (and (= 15 (length buf)) (= 0x43 (buf 0)))
    {:percent (buf 2)
     :state (get valve-states (buf 1) "unknown")
     :mv (+ (buf 3) (* 256 (buf 4)))}))

# ID 0x79: 1 is a controller leaving its slot, 2 one arriving.
(defn- valve-left? [buf]
  (and (= 2 (length buf)) (= 0x79 (buf 0)) (= 1 (buf 1))))

# 17 bytes: report ID, command 4, and a checksum the receiver insists on.
(def- compx-query
  (let [frame @"\x08\x04"]
    (buffer/push frame (string/repeat "\0" 14))
    (buffer/push-byte frame (band (- 0x55 (sum frame)) 0xff))))

(defn- compx-battery [buf]
  (when (and (>= (length buf) 8) (= 0x08 (buf 0)) (= 0x04 (buf 1)))
    {:percent (buf 6)
     :state (get compx-states (buf 7) "unknown")
     :mv 0}))

(defn- read-until [f timeout parse]
  (try
    (ev/with-deadline timeout
      (var out nil)
      (while (nil? out)
        (def buf (ev/read f 64))
        (when (nil? buf) (break))
        (set out (parse buf)))
      out)
    ([_] nil)))

(defn- query-compx [dev]
  (with [f (os/open (dev :node) :rw)]
    (ev/write f compx-query)
    (read-until f 1 compx-battery)))

(defn- listen-valve [dev timeout]
  (with [f (os/open (dev :node) :r)]
    (read-until f timeout valve-battery)))

(defn- once [timeout]
  (def devs (nodes))
  (def ch (ev/chan))
  (each dev devs
    (ev/spawn
      (ev/give ch [dev (try (case (dev :kind)
                              :valve (listen-valve dev timeout)
                              :compx (query-compx dev))
                            ([_] nil))])))
  (repeat (length devs)
    (def [dev bat] (ev/take ch))
    (when bat (emit-battery dev bat))))

## Watch mode: a fiber per node, and the main one rescanning for hotplug.

(def- watching @{})  # node -> dev, while its fiber lives
(def- seen @{})      # node -> os/clock of its last reading; nil once gone
(def- failed @{})    # node -> true: couldn't be opened. Forgotten on unplug.

(defn- gone [dev]
  (when (get seen (dev :node))
    (put seen (dev :node) nil)
    (emit "gone" :node (dev :node))))

(defn- report [dev bat]
  (put seen (dev :node) (os/clock))
  (emit-battery dev bat))

(defn- watch-valve [dev]
  (with [f (os/open (dev :node) :r)]
    (loop [buf :iterate (ev/read f 64)]
      (if-let [bat (valve-battery buf)]
        (report dev bat)
        (when (valve-left? buf) (gone dev))))))

(defn- watch-compx [dev interval]
  (forever
    (if-let [bat (query-compx dev)]
      (report dev bat)
      (gone dev))
    (ev/sleep interval)))

(defn- watch-node [dev interval]
  (put watching (dev :node) dev)
  (ev/spawn
    (def [ok err] (protect (case (dev :kind)
                             :valve (watch-valve dev)
                             :compx (watch-compx dev interval))))
    (gone dev)
    (put watching (dev :node) nil)
    (unless ok
      # EACCES, mostly
      (put failed (dev :node) true)
      (eprint "hid-battery: " (dev :node) ": " err))))

(defn- watch [interval]
  (forever
    (def present @{})
    (each dev (nodes)
      (put present (dev :node) true)
      (unless (or (get watching (dev :node)) (get failed (dev :node)))
        (watch-node dev interval)))
    (each node (keys failed)
      (unless (get present node) (put failed node nil)))
    # A controller that stopped reporting is asleep
    (each [node t] (pairs seen)
      (when (and t (> (- (os/clock) t) valve-stale)
                 (= :valve (get-in watching [node :kind])))
        (gone (get watching node))))
    (emit "tick")
    (ev/sleep rescan)))

(defmain [_ &opts
          watch? [-w --watch]
          timeout [-t --timeout seconds]
          interval [-i --interval seconds]]
  (def timeout (scan-number (or timeout "6")))
  (def interval (scan-number (or interval "30")))
  (unless (and timeout interval (> timeout 0) (> interval 0))
    (abort "SECONDS must be a positive number"))
  (if watch?
    (watch interval)
    (once timeout)))
