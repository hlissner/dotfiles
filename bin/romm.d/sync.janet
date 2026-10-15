#!/usr/bin/env janet
# Bring a device's ROMs, BIOS and saves into step with RomM.
#
# SYNOPSIS:
#   romm sync [--prune] [--states] [--only LEG] DEVICE
#
# DESCRIPTION:
#   ROMs are whatever the collection "Device: DEVICE" lists on RomM, read off
#   the NAS mount and rsynced into the device's own layout; BIOS likewise, and
#   any engine the device can't install itself (PICO-8) rides along from its
#   platform's bios/. Saves go through RomM's device-sync API, so the server
#   is the arbiter. udon's ROMs are the mount itself, so it only has a save leg.
#
#   Honours hey's -!: rsync, every POST and the sync bookkeeping are printed
#   instead of run.
#
#   REQUIRES: rsync, ssh, curl, sha1sum, rbw
#
# OPTIONS:
#   --prune
#     Delete what the collection no longer lists -- inside the platform
#     directories romm manages, and nowhere else.
#   --states
#     Also sync RetroArch save states, newest wins. Not part of the sync
#     protocol, so this is a plain upload/download.
#   --only LEG
#     roms, bios, apps or saves. All of them otherwise.
#
# ARGUMENTS:
#   1 DEVICE
#     udon     -- This PC. Saves only; the ROMs are the NFS mount.
#     machine  -- Steam Machine (EmuDeck + ES-DE).
#     deck     -- Steam Deck (EmuDeck + ES-DE).
#     rp6      -- Retroid Pocket 6 (DroidDeck, over termux sshd).
#     brick    -- TrimUI Brick (NextUI), over ssh or a mounted SD card.

(use hey)
(import hey/romm)

(defmain [_ device &opts
          prune? [--prune]
          states? [--states]
          only [--only leg]]
  (unless device (usage))
  (when (and only (not (index-of only ["roms" "bios" "apps" "saves"])))
    (abort "--only takes roms, bios, apps or saves, not %q" only))
  (def p (romm/profile device))
  (romm/check! p)
  (defn leg? [name] (and (p name) (or (nil? only) (= only (string name)))))
  (def roms (romm/collection-roms p))
  (echof :g "%s: %d ROMs in %q" device (length roms) (p :collection))
  (def ok
    (all identity
         [(if (leg? :roms) (romm/sync-roms! p roms :prune prune?) true)
          (if (leg? :bios) (romm/sync-bios! p roms) true)
          (if (leg? :apps) (romm/sync-apps! p roms) true)
          (if (leg? :saves) (romm/sync-saves! p roms) true)
          (if (and states? (leg? :states)) (romm/sync-states! p roms) true)]))
  (unless ok (exit 1)))
