#!/usr/bin/env janet
# Mount/unmount your removable storage drives.
#
# Requires udisks. Uses udisksctl to manage devices.
#
# SYNOPSIS:
#   mountmenu

(use hey)
(use hey/cmd)
(import hey/sys)
(import hey/rofi)
(import hey/vars)

(defn- removable-devices []
  (-?>> (get (json/decode
              ($<_ lsblk --json -po "tran,name,type,size,mountpoint,label,vendor,model,fstype")
              :keywords true)
             :blockdevices)
        (filter |(= (get $ :tran) "usb"))
        (map |(get $ :children []))
        flatten))

(def- *vars* (vars/new (:dir vars/temp :rofi :mountmenu)))
# TODO: untested!
(defn- handle-luks [dev]
  (not-implemented :handle-luks dev)
  (def mounts (:get *vars* :mounts))
  (try
    (if (dev :mountpoint)
      (let [mp (get mounts (dev :name))]
        (unless mp
          (abort "%s is not mounted" (dev :name)))
        ($<_ udisksctl umount -b ,mp)
        ($<_ udisksctl lock -b ,(dev :name))
        (put mounts (dev :name) nil)
        (:set *vars* :mounts mounts)
        true)
      (do
        (when-let [pass (rofi/read :placeholder "Passphrase" :password true)
                   passfile (path :runtime "mountmenu-pass")]
          (with-umask 8r077
            (defer (os/rm passfile)
              (spit (path :runtime "mountmenu-pass") pass)
              (def buf @"")
              (unless (do? $? udisksctl unlock -b ,(dev :name) --key-file ,passfile > ,buf)
                (abort "Failed to unlock %s" (dev :name)))
              (def mp (peg/match '(* "Unlocked " (capture :w+) " as " (capture :w+) ".") buf))
              (unless mp # FIXME
                (abort "Failed to extract mount point from: %s" buf))
              (unless (do? $? udisksctl mount -b ,mp)
                (abort "Failed to mount %s: %s" mp buf))
              (put mounts (dev :name) mp)
              (:set *vars* :mounts mounts)
              true)))))
    ([err fib]
     (if (= (first err) :error)
       (do
         (when-let [mp (get mounts (dev :name))]
           (do? $? udisksctl unmount -b ,mp))
         (do? $? udisksctl lock -b ,(dev :name))
         (rofi/error err))
       (propagate err fib)))))

(defn- handle-part [dev]
  (let [op (if (dev :mountpoint) :unmount :mount)]
    (echof "Trying to %s %s" op (or (dev :mountpoint) (dev :name)))
    (do? $? udisksctl ,op -b ,(dev :name))))

(defn- handle [dev]
  (unless dev (abort "Aborted"))
  (when (case (dev :type)
          "part" (handle-part dev)
          "crypto_LUKS" (handle-luks dev)
          (abort "Unknown device type (%s) for %s" (dev :type) (dev :name)))
    (sys/notify (if (dev :mountpoint)
                  (fmt "Unmounted %s from %s" (dev :name) (dev :mountpoint))
                  (fmt "Mounted %s to %s"
                       (dev :name)
                       (get (find |(= (get $ :name) (dev :name)) (removable-devices))
                            :mountpoint)))
                :icon "drive-harddisk"
                :sound "blip"
                :id 9413)))

(defmain [_ & args]
  (rofi/with [rofi :theme "devmenu"]
    (:add rofi "Test"))
  # (let [devs (removable-devices)]
  #   (if (empty? devs)
  #     (rofi/error "No mountable filesystems found")
  #     (handle
  #      (rofi/with [rofi :theme "devmenu"]
  #        (each m devs
  #          (def mp (m :mountpoint))
  #          (:add rofi (fmt "<b>%-26s</b> %-8s %-14s%s"
  #                          (peg/replace '(* "/dev/") "" (string (m :name)))
  #                          (or (m :size) "")
  #                          (or (m :fstype) "")
  #                          (if (m :label) (fmt " <span alpha=\"50%%\">%s</span>" (m :label)) ""))
  #                :icon (if mp "checkbox-checked-symbolic" "checkbox-symbolic")
  #                :data m))))))
  )
