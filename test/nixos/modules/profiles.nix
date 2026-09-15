# test/nixos/modules/profiles.nix --- tests for modules/profiles/
#
# Two dozen modules under modules/profiles/ switch on the profile strings by
# `elem` or `hasPrefix`, and nothing validates them, so a typo in a host
# silently disables hardware instead of failing. Pinned here: the two profiles
# with real branching in them, and the copy of the set hey.info publishes.

{ evalConfig, lib, ... }:

let
  hardware = list: evalConfig [{ modules.profiles.hardware = list; }];
  pipewire = list: (hardware list).services.pipewire;
in {
  # hardware/ssd.nix points trim at fstrim or at zfs depending on whether any
  # filesystem is zfs. Neither services.fstrim.enable nor
  # boot.initrd.availableKernelModules is a usable discriminator for "is the
  # ssd profile on" -- nixpkgs enables fstrim and lists nvme by default -- so
  # this asserts on the zfs branch.
  testSsdTrimsWithFstrimOrZfs =
    let ext4 = hardware [ "ssd" ];
        zfs = evalConfig [{
          modules.profiles.hardware = [ "ssd" ];
          fileSystems."/".fsType = lib.mkForce "zfs";
        }];
    in {
      expr = {
        ext4 = { fstrim = ext4.services.fstrim.enable; zfs = ext4.services.zfs.trim.enable; };
        zfs  = { fstrim = zfs.services.fstrim.enable;  zfs = zfs.services.zfs.trim.enable; };
      };
      expected = {
        ext4 = { fstrim = true; zfs = false; };
        zfs  = { fstrim = false; zfs = true; };
      };
    };

  # "audio/realtime" enables the base audio profile too, because audio.nix
  # matches on the "audio" prefix rather than the exact string; the realtime
  # tuning needs the exact one. Easy to miss and easy to break.
  testAudioIsMatchedByPrefix = {
    expr = {
      realtime = (pipewire [ "audio/realtime" ]).enable
                 && (pipewire [ "audio/realtime" ]).extraConfig.pipewire ? "99-lowlatency";
      plain    = (pipewire [ "audio" ]).enable
                 && !((pipewire [ "audio" ]).extraConfig.pipewire or {} ? "99-lowlatency");
    };
    expected = { realtime = true; plain = true; };
  };

  # The profiles set is republished for shell feature-detection via hey.info.
  # Unset reads as null, not "": it reaches Lua through generators.toLua,
  # where a null drops the key entirely, so hey.profiles.platform is absent
  # rather than an empty string that would test as truthy.
  testHeyInfoMirrorsProfiles = {
    expr =
      let p = (evalConfig [{
            modules.profiles = { role = "workstation"; hardware = [ "ssd" ]; };
          }]).hey.info.profiles;
      in { inherit (p) role hardware platform; };
    expected = { role = "workstation"; hardware = [ "ssd" ]; platform = null; };
  };
}
