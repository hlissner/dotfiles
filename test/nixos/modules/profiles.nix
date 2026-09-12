# test/nixos/modules/profiles.nix --- tests for modules/profiles/
#
# modules/profiles/default.nix declares five plain strings and lists, and two
# dozen modules under modules/profiles/ switch on their contents by string
# comparison, `elem`, or `hasPrefix`. Nothing validates those strings, so a
# typo in a host silently disables hardware instead of failing. These tests pin
# what each value is supposed to switch on.

{ evalConfig, lib, ... }:

let
  # A single option that resolves to a different value under each role, which
  # makes it a cheap three-way discriminator.
  governor = profiles:
    (evalConfig [{ modules.profiles = profiles; }]).powerManagement.cpuFreqGovernor;

  hardware = list: evalConfig [{ modules.profiles.hardware = list; }];
in {
  ## Roles are matched by string equality, so exactly one activates.

  testWorkstationUsesNetworkd = {
    expr = (evalConfig [{ modules.profiles.role = "workstation"; }]).networking.useNetworkd;
    expected = true;
  };

  # Distinct from the workstation case, and a reminder that role/server.nix is
  # live code with no host currently using it.
  testServerEnablesNixGc = {
    expr = (evalConfig [{ modules.profiles.role = "server"; }]).nix.gc.automatic;
    expected = true;
  };

  ## Hardware is a list matched by `elem`, except audio, which uses hasPrefix.

  # hardware/ssd.nix is the only profile with real branching in it: it points
  # trim at fstrim or at zfs depending on whether any filesystem is zfs. Note
  # neither services.fstrim.enable nor boot.initrd.availableKernelModules is a
  # usable discriminator for "is the ssd profile on" -- nixpkgs enables fstrim
  # and lists nvme by default -- so these assert on the zfs branch instead.
  testSsdOnExt4RootTrimsWithFstrim = {
    expr =
      let c = hardware [ "ssd" ];
      in { fstrim = c.services.fstrim.enable; zfs = c.services.zfs.trim.enable; };
    expected = { fstrim = true; zfs = false; };
  };

  testSsdOnZfsRootTrimsWithZfs = {
    expr =
      let c = evalConfig [{
            modules.profiles.hardware = [ "ssd" ];
            fileSystems."/".fsType = lib.mkForce "zfs";
          }];
      in { fstrim = c.services.fstrim.enable; zfs = c.services.zfs.trim.enable; };
    expected = { fstrim = false; zfs = true; };
  };

  # Without the profile, zfs trim is left at nixpkgs' own default, which is the
  # opposite of what the profile sets on an ext4 root.
  testHardwareUnsetLeavesZfsTrimAlone = {
    expr = (hardware []).services.zfs.trim.enable;
    expected = true;
  };

  # "audio/realtime" enables the base audio profile too, because audio.nix
  # matches on the "audio" prefix rather than the exact string. Pinning this
  # because the prefix match is easy to miss and easy to break.
  testAudioIsMatchedByPrefix = {
    expr = (hardware [ "audio/realtime" ]).services.pipewire.enable;
    expected = true;
  };

  testAudioRealtimeAddsLowLatencyConfig = {
    expr = (hardware [ "audio/realtime" ]).services.pipewire.extraConfig.pipewire
             ? "99-lowlatency";
    expected = true;
  };

  # Plain "audio" gets pipewire but not the realtime tuning, which needs the
  # exact string.
  testPlainAudioSkipsRealtime = {
    expr = (hardware [ "audio" ]).services.pipewire.extraConfig.pipewire or {}
             ? "99-lowlatency";
    expected = false;
  };

  ## The profiles set is republished for shell feature-detection via
  ## hey.info, which modules/hey.nix serialises to info.json.

  testHeyInfoMirrorsProfiles = {
    expr = (evalConfig [{
      modules.profiles = { role = "workstation"; hardware = [ "ssd" ]; };
    }]).hey.info.profiles;
    expected = {
      role = "workstation";
      hardware = [ "ssd" ];
      networks = [];
      platform = "";
      user = "test";
    };
  };
}
