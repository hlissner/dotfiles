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
  # boot.initrd.availableKernelModules is a usable discriminator for "is the ssd
  # profile on" -- nixpkgs enables fstrim and lists nvme by default -- so this
  # asserts on the zfs branch.
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
  # tuning needs the exact one. Easy to miss and easy to break. The tuning is
  # whatever fragments the profile drops in; none is named here.
  testAudioIsMatchedByPrefix = {
    expr = {
      realtime = (pipewire [ "audio/realtime" ]).enable
                 && (pipewire [ "audio/realtime" ]).extraConfig.pipewire != {};
      plain    = (pipewire [ "audio" ]).enable
                 && (pipewire [ "audio" ]).extraConfig.pipewire or {} == {};
    };
    expected = { realtime = true; plain = true; };
  };

  # The small buffer belongs to JACK clients only. A global default in
  # client.conf once made every notification sound crackle (a non-RT process
  # with 2.7ms of slack), so this pins where it lives, not what it is.
  testRealtimeLatencyIsJackOnly =
    let rt = (pipewire [ "audio/realtime" ]).extraConfig;
        # fragment -> section -> key, whatever the section is called.
        latency = conf: lib.any (f: lib.any (s: lib.isAttrs s && s ? "node.latency") (lib.attrValues f))
                                (lib.attrValues conf);
    in {
      expr = {
        jack   = latency (rt.jack or {});
        client = latency (rt.client or {});
      };
      expected = { jack = true; client = false; };
    };

  # nixpkgs provisions ensurePrinters from cups.service's ExecStartPost, and an
  # `everywhere` queue needs the printer answering to do it. With ipp-usb that
  # once meant an unplugged printer killed cupsd outright, LAN share and all.
  # Pinned: provisioning hangs off ipp-usb, and nothing of it is left on cups.
  testIppUsbProvisioningIsNotCupsPostStart =
    let c = evalConfig [{
          modules.profiles.hardware = [ "printer" ];
          services.ipp-usb.enable = true;
          hardware.printers.ensurePrinters = [{
            name = "p"; deviceUri = "ipp://localhost:60000/ipp/print"; model = "everywhere";
          }];
        }];
    in {
      expr = {
        cups = c.systemd.services.cups.serviceConfig.ExecStartPost;
        ensure = lib.elem "ipp-usb.service" c.systemd.services.ensure-printers.wantedBy
                 && lib.hasInfix "lpadmin -p p" c.systemd.services.ensure-printers.script;
      };
      expected = { cups = []; ensure = true; };
    };

  # The profiles set is republished for shell feature-detection via hey.info.
  # Unset reads as null, not "": it reaches Lua through generators.toLua, where
  # a null drops the key entirely, so hey.profiles.platform is absent rather
  # than an empty string that would test as truthy.
  testHeyInfoMirrorsProfiles = {
    expr =
      let p = (evalConfig [{
            modules.profiles = { role = "workstation"; hardware = [ "ssd" ]; };
          }]).hey.info.profiles;
      in { inherit (p) role hardware platform; };
    expected = { role = "workstation"; hardware = [ "ssd" ]; platform = null; };
  };
}
