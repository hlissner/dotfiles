#!/usr/bin/env janet
# Prepare a device for romm sync: register it with RomM and lay out its dirs.
#
# SYNOPSIS:
#   romm init DEVICE
#
# DESCRIPTION:
#   Checks the device answers and that RomM has a "Device: DEVICE" collection,
#   registers the device for save sync if it does saves, and creates the
#   platform directories the collection needs. Safe to repeat; a registered
#   device stays registered. Nothing is copied -- that's sync.
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
  (romm/check! p)
  (echof :check "%s answers" (or (p :target) "localhost"))
  (def roms (romm/collection-roms p))
  (echof :check "%q: %d ROMs" (p :collection) (length roms))
  (when (p :saves)
    (if-let [id (romm/register! p)]
      (echof :check "registered as device %s" id)))
  (when (p :roms)
    (def {:plan plan :unmapped unmapped} (romm/roms->plan p roms))
    (each [slug names] (pairs unmapped)
      (echof :warn "no folder for platform %s (%d ROMs)" slug (length names)))
    (each {:slug slug :folder folder} plan
      (romm/mkdir! p (path/join (get-in p [:roms :root]) folder))
      (echof :check "%s/ (%s)" folder slug)))
  (when-let [bios (p :bios)]
    (romm/mkdir! p (bios :root))
    (echof :check "%s/" (bios :root)))
  (each {:slug slug :folder folder} (romm/apps->plan p roms)
    (romm/mkdir! p folder)
    (echof :check "%s/ (%s)" folder slug)))
