#!/usr/bin/env janet
# Mount/unmount your removable storage drives.
#
# Requires udisks. Uses udisksctl to manage devices.
#
# SYNOPSIS:
#   mountmenu

(use hey)
(use hey/cmd)
(use sh)
(import hey/sys)
(import hey/rofi)

(def- *notify-id* 9413)

(def- *unlocked-peg*
  (peg! ~(* "Unlocked " (thru " as ") (capture (to (* "." (any :s) -1))))))

(defn- luks? [dev]
  (= (dev :fstype) "crypto_LUKS"))

(defn- mountpoint [dev]
  (or (dev :mountpoint)
      (get (dev :crypt) :mountpoint)))

(defn- removable? [dev]
  # `tran` and `rm` are only reported on the top-level disk. USB enclosures
  # routinely report rm=false and card readers report tran=mmc.
  (or (= (dev :tran) "usb") (dev :rm)))

(defn- actionable
  "Flatten DEVS into the devices that can be mounted, unmounted or unlocked."
  [devs]
  (catseq [dev :in (or devs [])]
    (def children (get dev :children []))
    (cond
      # A LUKS container stands in for the mapper device it unlocks to.
      (luks? dev) [(put dev :crypt (first children))]
      # A device formatted without a partition table has no children, but is
      # mountable itself.
      (empty? children) (if (dev :fstype) [dev] [])
      (actionable children))))

(defn- removable-devices []
  (-?>> (get (json/decode
               ($<_ lsblk --json -po "tran,rm,name,type,size,mountpoint,label,vendor,model,fstype")
               :keywords true)
             :blockdevices)
        (filter removable?)
        actionable))

(defn- mountpoint-of [name]
  (some |(and (= ($0 :name) name) (mountpoint $0))
        (removable-devices)))

(defn- unlock
  "Prompt for a passphrase and unlock DEV. Returns its mapper device."
  [dev]
  (def passfile (path :runtime "mountmenu-pass"))
  (when-let [pass (rofi/read :placeholder "Passphrase" :password true)]
    (with-umask 8r077
      (spit passfile pass))
    (defer (ignore-errors (os/rm passfile))
      (def buf @"")
      (unless (do? $? udisksctl unlock -b ,(dev :name) --key-file ,passfile > ,buf)
        (abort "Failed to unlock %s" (dev :name)))
      (or (first (peg/match *unlocked-peg* buf))
          (abort "Could not read unlocked device from: %s" buf)))))

(defn- handle-luks [dev]
  (if-let [crypt (dev :crypt)]
    (do
      (when (crypt :mountpoint)
        (unless (do? $? udisksctl unmount -b ,(crypt :name))
          (abort "Failed to unmount %s" (crypt :mountpoint))))
      (unless (do? $? udisksctl lock -b ,(dev :name))
        (abort "Failed to lock %s" (dev :name)))
      :lock)
    (when-let [node (unlock dev)]
      (unless (do? $? udisksctl mount -b ,node)
        # Don't leave the container unlocked if we can't mount it.
        (do? $? udisksctl lock -b ,(dev :name))
        (abort "Failed to mount %s" node))
      :mount)))

(defn- handle-part [dev]
  (def op (if (dev :mountpoint) :unmount :mount))
  (echof "Trying to %s %s" op (or (dev :mountpoint) (dev :name)))
  (when (do? $? udisksctl ,op -b ,(dev :name))
    op))

(defn- handle [dev]
  # Rofi hands back the raw query when nothing was selected.
  (unless (dictionary? dev) (abort "Aborted"))
  (def mp (mountpoint dev))
  (def op (if (luks? dev) (handle-luks dev) (handle-part dev)))
  (when op
    (sys/notify (case op
                  :mount   (fmt "Mounted %s to %s"
                                (dev :name)
                                (or (mountpoint-of (dev :name)) "?"))
                  :unmount (fmt "Unmounted %s from %s" (dev :name) mp)
                  :lock    (if mp
                             (fmt "Unmounted and locked %s" (dev :name))
                             (fmt "Locked %s" (dev :name))))
                :icon "drive-harddisk"
                :sound "blip"
                :id *notify-id*)))

(defmain [_]
  (def devs (removable-devices))
  (if (empty? devs)
    (rofi/notice "No mountable filesystems found")
    (handle
      (rofi/with [rofi :theme "devmenu"]
        (each m devs
          (def label (or (m :label) (get (m :crypt) :label)))
          (:add rofi (fmt "<b>%-26s</b> %-8s %-14s%s"
                          (string/no-prefix "/dev/" (string (m :name)))
                          (or (m :size) "")
                          (or (m :fstype) "")
                          (if label
                            (fmt " <span alpha=\"50%%\">%s</span>" (rofi/escape label))
                            ""))
                :icon (if (mountpoint m) "checkbox-checked-symbolic" "checkbox-symbolic")
                :data m))))))
