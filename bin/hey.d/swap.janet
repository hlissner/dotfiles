#!/usr/bin/env janet
# Swap nix-store symlinks with mutable copies (and back)
#
# SYNOPSIS:
#   swap [-u] [-f] FILES...
#   swap [-l|--list]
#   swap [--reset]
#
# DESCRIPTION:
#   The purpose is so you can have copies of your dotfiles that can be modified
#   in place (so you can iterate on them quickly instead of 'hey re'ing between
#   changes). Run again to restore the old link(s).
#
#   WARNING: backup your copies before unswapping them, or they will be
#   destroyed when restored!
#
# OPTIONS:
#   -f
#     Don't ask for confirmation; overwrite files as needed.
#   -u
#     Unswap the targeted files instead of trying to swap them.
#   -l, --ls
#     List all known swapped files.
#   --reset
#     Unswap all known swapped files.

(use hey)
(use hey/cmd)

(def- *store* (delay (path :data "swap")))
(def- *ext* ".swapped")
(def- *swapped* ".swapped")

(defn- list []
  (if (path/file? (*store*))
    (filter |(path/file? (string $ *ext*)) (unmarshal (string/chomp (slurp (*store*)))))
    @[]))

(defn- save [swapped]
  (spit (*store*) (marshal swapped)))

(defn- each-file [& paths]
  (each path paths
    (case (os/stat path :mode)
      nil (echof :err "Skipping %s (does not exist)" path)
      :directory (each-file ;(path/files-in path))
      :file (yield path))))

(defn- swap [paths &opt force?]
  (when (empty? paths)
    (abort "Nothing to swap"))
  (let [swapped (list)
        new-swapped @[;swapped]
        force (if force? ["-f"] [])]
    (each path (coro (each-file ;paths))
      (log 2 "Trying to swap %s" path)
      (let [spath (string path *ext*)]
        (cond (path/exists? spath)
              (echof :warn "Already swapped: %s" path)
              (not (path/symlink? path))
              (echof :err "Skipping %s (not a nix-store symlink)" path)
              (do (echof :pass "Swapping %s" path)
                  (do? $ mv ,;force ,path ,spath)
                  (do? $ cp ,;force ,spath ,path)
                  (do? $ chmod u+rw ,path)
                  (array/push new-swapped (os/realpath path))))))
    (if (or (dryrun?)
            (deep= swapped new-swapped))
      (exit 1)
      (save new-swapped))))

(defn- unswap [paths &opt force?]
  (when (empty? paths)
    (abort "Nothing to unswap"))
  (let [removed @[]
        force (if force? ["-f"] [])]
    (each path (coro (each-file ;paths))
      (log 2 "Trying to unswap %s" path)
      (let [swapfile (string path *ext*)]
        (if (not (path/exists? swapfile))
          (echof :warn "File not swapped: %s" path)
          (do (echof :pass "Unswapping %s" path)
              (do? $ mv ,;force ,swapfile ,path)
              (array/push removed path)))))
    (if (or (dryrun?)
            (empty? removed))
      (exit 1)
      (let [swapped (list)]
        (each p removed (array/remove-elt swapped p))
        (save swapped)))))

(defcmd swap [_ & targets &opts
              unswap? -u
              force? -f
              list? [-l --list]
              reset? --reset]
  (os/with-lock (string (*store*) ".lock")
    (cond list? (echo ;(list))
          reset? (unswap (list) force?)
          (empty? targets) (abort "Nothing to swap")
          (if unswap?
            (unswap targets force?)
            (swap targets force?)))))
