#!/usr/bin/env janet
# Regression tests for bin/romm, bin/romm.d/* and lib/hey/romm.janet.
#
# Nothing here reaches RomM or a device. The verbs' first act is a probe and
# their second is a GET, so what's left to pin is the half that decides what
# to run: the device list the headers complete from, the platform maps, and
# every builder that turns a RomM answer into an rsync or a negotiate body.

(use judge)
(use sh)
(import hey)
(import hey/romm)
(import spork/json)

(def- bin (hey/path :home "bin/hey"))
(def- fixtures (hey/path :test "hey/romm.d"))
(def- roms ((json/decode (slurp (hey/path/join fixtures "roms.json")) true) :items))
# Read off disk, so a new verb is held to the device list the moment it exists.
(def- scripts
  (sorted (seq [file :in (os/dir (hey/path :home "bin/romm.d"))
                :when (string/has-suffix? ".janet" file)]
            (hey/string/no-suffix ".janet" file))))

(defn- romm [& args]
  (def out @"")
  (def code (first (run ,bin .romm ,;args > ,out > [stderr out])))
  [code (string/trim out)])

(defn- says? [[_ out] text] (not= nil (string/find text out)))

(defn- header-devices
  ``The literal list _hey completes DEVICE from, per `hey help --dump`.``
  [script]
  (def out @"")
  ($? ,bin help --dump .romm ,script > ,out)
  (def line (find |(string/has-prefix? "1:device:" $0) (string/split "\n" (string out))))
  (sorted (peg/match '(* "1:device:((" (some (* (<- :w+) ":\"" (thru "\"") (any " "))) "))")
                     (or line ""))))

(def- deck (romm/profile "deck"))
(def- rp6 (romm/profile "rp6"))
(def- brick (romm/profile "brick"))
# A card in a reader rather than a Brick on the network.
(def- card (merge brick {:target "/run/media/SD"}))


(deftest romm/devices-match-headers
  # Each verb's header carries the same literal DEVICE list, and it's the
  # profile table's: a device added to one and not the other either doesn't
  # complete or completes to "No such device".
  (test (romm/devices) @["brick" "deck" "machine" "rp6" "udon"])
  (test (filter |(not (deep= (header-devices $0) (romm/devices))) scripts) @[]))

(deftest romm/usage
  (test (filter |(not (says? (romm $0) "Usage:")) scripts) @[])
  (test (first (romm "status" "nope")) 127)
  (test (says? (romm "status" "nope") "No such device: nope") true))

(deftest romm/es-de-map-is-total
  # Every system modules/games/emulators.nix defines is a folder some RomM slug
  # maps to on an EmuDeck box, and no two slugs share a folder.
  (def systems
    (peg/match '(* (thru "    table = {")
                   (any (+ (* "\n      " (<- :w+) " = {") (if-not "\n    }" 1))))
               (slurp (hey/path :modules "games/emulators.nix"))))
  (def dirs (get-in deck [:roms :dirs]))
  (test (sorted systems)
        @["dreamcast" "gamegear" "gba" "gc" "genesis" "mastersystem" "n3ds" "n64" "nds"
          "nes" "pico8" "ps2" "ps3" "psp" "psvita" "psx" "saturn" "snes" "switch" "wii"])
  (test (filter |(not (index-of $0 (values dirs))) systems) @[])
  (test (= (length (distinct (values dirs))) (length dirs)) true))

(deftest romm/targets
  (test (romm/remote? deck) true)
  (test (romm/remote? card) false)
  (test (romm/remote? (romm/profile "udon")) false)
  (test (romm/ssh-target deck) "deck@deck.lan")
  (test (romm/dest deck "Emulation/roms/snes") "deck@deck.lan:Emulation/roms/snes/")
  (test (romm/dest card "/mnt/SDCARD/Roms/X") "/mnt/SDCARD/Roms/X/")
  (test (romm/resolve-path card "Roms") "/run/media/SD/Roms"))

(deftest romm/rsync-argv
  # Never -a: links, perms and owners all fail on Android and FAT.
  (test (romm/rsync-argv deck "/src/" "d:dst/")
        ["rsync" "-rtv" "--partial" "/src/" "d:dst/"])
  (test (romm/rsync-argv deck "/src/" "d:dst/" :exec true)
        ["rsync" "-rtv" "--partial" "-E" "/src/" "d:dst/"])
  (test (romm/rsync-argv rp6 "/src/" "d:dst/" :list "/l" :prune true)
        ["rsync" "-rtv" "--partial"
         "--from0" "--include-from=/l" "--exclude=*"
         "--delete" "--delete-excluded"
         "-e" "ssh -p 8022"
         "--no-perms" "--no-owner" "--no-group" "--omit-dir-times" "--size-only"
         "/src/" "d:dst/"])
  # A mounted card gets no -e, whatever :ssh says.
  (test (romm/rsync-argv (merge card {:ssh ["-p" "22"]}) "/src/" "/dst/" :list "/l")
        ["rsync" "-rtv" "--partial" "--from0" "--include-from=/l" "--exclude=*"
         "--no-perms" "--no-owner" "--no-group" "--modify-window=2"
         "/src/" "/dst/"]))

(deftest romm/include-rules
  # Anchored, glob characters escaped, NUL-separated (so a name starting with
  # # or ; isn't a comment), and a directory taken with its contents.
  (test (string/split "\0" (romm/include-rules ["Game (USA) [!].zip" "Disc Set/" "#1.nes" "a*b?c\\d"]))
        @["+ /Game (USA) \\[!].zip" "+ /Disc Set/" "+ /Disc Set/**" "+ /#1.nes" "+ /a\\*b\\?c\\\\d"]))

(deftest romm/roms-plan
  (def {:plan plan :unmapped unmapped} (romm/roms->plan deck roms))
  (test (map |[($0 :slug) ($0 :folder) ($0 :files)] plan)
        @[["ngc" "gc" @["Metroid Prime (USA).rvz"]]
          ["psx" "psx" @["Final Fantasy VII (USA)/"]]
          ["snes" "snes" @["Chrono Trigger (USA).sfc" "EarthBound (USA) [!].zip"]]])
  (test (map |[($0 :src) ($0 :dest)] plan)
        @[["/media/nas/media/games/ngc/roms/" "deck@deck.lan:Emulation/roms/gc/"]
          ["/media/nas/media/games/psx/roms/" "deck@deck.lan:Emulation/roms/psx/"]
          ["/media/nas/media/games/snes/roms/" "deck@deck.lan:Emulation/roms/snes/"]])
  (test unmapped @{"atari2600" @["Pitfall.a26"]})
  # NextUI names its folders by tag, and its bios dirs by the tag alone.
  (test (map |($0 :dest) ((romm/roms->plan brick roms) :plan))
        @["brick.lan:/mnt/SDCARD/Roms/Sony PlayStation (PS)/"
          "brick.lan:/mnt/SDCARD/Roms/Super Nintendo Entertainment System (SFC)/"])
  (test (romm/firmware->plan brick [{:file_name "scph1001.bin"}] "psx")
        {:dest "brick.lan:/mnt/SDCARD/Bios/PS/"
         :files @["scph1001.bin"]
         :folder "PS"
         :slug "psx"
         :src "/media/nas/media/games/psx/bios/"})
  # EmuDeck's bios dir is flat and mirrored whole; there's no per-platform plan.
  (test (romm/firmware->plan deck [{:file_name "scph1001.bin"}] "psx") nil))

(deftest romm/apps-plan
  # The engine goes only where its platform's ROMs do, and never to the rp6:
  # it's an x86 binary.
  (def with-pico (array/concat @[] roms [{:platform_fs_slug "pico" :fs_name "celeste.p8.png"}]))
  (test (romm/apps->plan deck roms) @[])
  (test (romm/apps->plan deck with-pico)
        @[{:dest "deck@deck.lan:Applications/pico-8/"
           :folder "Applications/pico-8"
           :slug "pico"
           :src "/media/nas/media/games/pico/bios/amd64/"}])
  # NextUI gets the two files its pak reads, not the whole raspi zip.
  (test (romm/apps->plan brick with-pico)
        @[{:dest "brick.lan:/mnt/SDCARD/Bios/PICO/"
           :files ["pico8_64" "pico8.dat"]
           :folder "/mnt/SDCARD/Bios/PICO"
           :slug "pico"
           :src "/media/nas/media/games/pico/bios/arm/"}])
  (test (romm/apps->plan rp6 with-pico) @[])
  # The legs rp6 opts out of must really be gone, not merged in as nils.
  (test (filter |(rp6 $0) [:apps :saves :states]) @[]))

(deftest romm/nextui-tag
  (test (romm/nextui/tag "Game Boy Advance (GBA)") "GBA")
  (test (romm/nextui/tag "Sony PlayStation (PS)") "PS")
  (test (romm/nextui/tag "GBA") "GBA"))

(deftest romm/api-url
  (test (romm/api/url "/api/roms" {:collection_id 3 :limit 100 :offset 0})
        "https://romm.home.lissner.net/api/roms?collection_id=3&limit=100&offset=0")
  (test (romm/api/url "/api/collections") "https://romm.home.lissner.net/api/collections")
  (test (romm/api/url "/api/x" {:q "a b&c" :none nil}) "https://romm.home.lissner.net/api/x?q=a%20b%26c"))

(deftest romm/time
  # RomM's timestamps are UTC with microseconds; mine are UTC to the second.
  (test (romm/iso->time "2026-10-14T12:34:56.123456") 1791981296)
  (test (romm/time->iso 1791981296) "2026-10-14T12:34:56Z")
  (test (romm/time->iso 0) "1970-01-01T00:00:00Z"))

(deftest romm/parse-sha1sum
  (test (romm/parse-sha1sum "4fbe4a465f758f9d6d1ea54042160414ba713bbf  /a/b c.srm\n")
        @{"/a/b c.srm" "4fbe4a465f758f9d6d1ea54042160414ba713bbf"}))

(deftest romm/saves
  (def dir (hey/path/join fixtures "saves"))
  (def scan (romm/scan-saves dir))
  (test (sorted (keys scan))
        @["Snes9x/Chrono Trigger (USA).srm" "Snes9x/EarthBound (USA) [!].srm" "Snes9x/Nobody.srm"])
  (test (get-in scan ["Snes9x/Chrono Trigger (USA).srm" :sha1]) "4fbe4a465f758f9d6d1ea54042160414ba713bbf")
  (test (get-in scan ["Snes9x/Chrono Trigger (USA).srm" :size]) 6)
  # Chrono is unchanged, EarthBound's hash moved, Nobody has no ROM, and the
  # manifest remembers a save the device has since lost.
  (def manifest
    @{"Snes9x/Chrono Trigger (USA).srm" {:sha1 "4fbe4a465f758f9d6d1ea54042160414ba713bbf" :rom_id 11 :save_id 101}
      "Snes9x/EarthBound (USA) [!].srm" {:sha1 "0000" :rom_id 12 :save_id 102}
      "Snes9x/Gone.srm" {:sha1 "1111" :rom_id 13 :save_id 103}})
  (def diff (romm/saves/diff manifest scan (romm/saves/index roms)))
  (test (map |($0 :operation_id) (diff :created)) @[])
  (test (map |[($0 :operation_id) ($0 :rom_id) ($0 :save_id) ($0 :filename) ($0 :sha1) ($0 :file_size)]
             (diff :modified))
        @[["Snes9x/EarthBound (USA) [!].srm" 12 102 "EarthBound (USA) [!].srm"
           "44d476274f1e50bef909be22f69b1c205fb4e273" 5]])
  (test (diff :deleted) @[{:filename "Gone.srm" :operation_id "Snes9x/Gone.srm" :rom_id 13 :save_id 103}])
  (test (diff :unmatched) @["Snes9x/Nobody.srm"])
  # With no manifest, everything with a ROM is new.
  (test (map |($0 :rom_id) ((romm/saves/diff @{} scan (romm/saves/index roms)) :created)) @[11 12])
  (def body (romm/saves/client-state "dev-1" 1792000000 diff 1791981296 "retroarch"))
  (test (body :device_id) "dev-1")
  (test (body :device_time) "2026-10-14T12:34:56Z")
  (test (body :emulators) ["retroarch"])
  (test (get-in body [:client_state :last_sync_time]) "2026-10-14T17:46:40Z")
  (test (length (get-in body [:client_state :saves :modified])) 1)
  (test (get-in (romm/saves/client-state "dev-1" nil diff 0 "retroarch") [:client_state :last_sync_time]) nil))

(deftest romm/saves-index
  # Two ROMs with one basename across platforms can't be told apart by a save.
  (def index (romm/saves/index [{:id 1 :fs_name "Tetris.gb"} {:id 2 :fs_name "Tetris.nes"} {:id 3 :fs_name "Zelda.sfc"}]))
  (test (index "Tetris") :ambiguous)
  (test (get-in index ["Zelda" :id]) 3))
