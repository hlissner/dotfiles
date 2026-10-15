#!/usr/bin/env janet
# Where a device stands: reachable, registered, last synced, what it gets.
#
# SYNOPSIS:
#   romm status DEVICE
#
# DESCRIPTION:
#   Reads only. One ssh probe, one look at the local bookkeeping, one trip to
#   RomM for the collection's size.
#
#   REQUIRES: ssh, curl, rbw
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

(defmain [_ device]
  (unless device (usage))
  (def p (romm/profile device))
  (def s (romm/status p))
  (echof "%s (%s): %s" (s :device) (s :target)
         (if (s :reachable) "reachable" "unreachable"))
  (echof "registered: %s" (or (s :registered) "no"))
  (echof "last sync:  %s" (or (s :last-sync) "never"))
  (echof "legs:       %s" (string/join (map string (s :legs)) " "))
  (when (s :reachable)
    (def roms (romm/collection-roms p))
    (echof "%q: %d ROMs" (p :collection) (length roms))
    (when (p :roms)
      (each [slug names] (pairs ((romm/roms->plan p roms) :unmapped))
        (echof :warn "no folder for platform %s (%d ROMs)" slug (length names))))))
