#!/usr/bin/env janet
# Preview and copy a GTK icon.
#
# SYNOPSIS:
#   iconmenu

(use hey)
(use hey/cmd)
(use sh)
(import hey/sys)
(import hey/rofi)

(defn- icons []
  (coro
   (let [tmpfile "/tmp/icons"
         seen @{}]
     (unless (path/exists? tmpfile)
       ($? fd -a -L '.svg' /etc/profiles/per-user/hlissner/share/icons > ,tmpfile))
     (with [f (file/open "/tmp/icons" :r)]
       (each file (file/lines f)
         (def file (string/trim file))
         (def id (path/basename file))
         (unless (get seen id)
           (put seen id true)
           (yield [(path/no-ext id) file])))))))

(defmain [_ & args]
  (pp (rofi/with [r :theme "~/projects/dotfiles/nixos/modules/themes/autumnal/config/rofi/themes/iconmenu.rasi"]
        (each [id file] (icons)
          (:add r id :icon file)
          ))))
