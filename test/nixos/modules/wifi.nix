# test/nixos/modules/wifi.nix --- tests for modules/profiles/hardware/wifi.nix
#
# The shell probes D-Bus at startup and silently downgrades to a wifi-less
# backend if it finds neither NetworkManager, wpa_supplicant, nor iwd. Nothing
# in a build catches that (the failure is a greyed-out toggle in a settings
# panel) so I test for it myself. Which daemon is my call; that there's exactly
# one of each job is not.

{ evalConfig, lib, ... }:

with lib;
let
  on = evalConfig [{
    modules.profiles.role = "workstation";
    modules.profiles.hardware = [ "wifi" ];
  }];

  nm = on.networking.networkmanager;
  iwd = on.networking.wireless.iwd;
  # NetworkManager can drive iwd itself, in which case that's one daemon, not
  # two.
  iwdAlone = iwd.enable && !(nm.enable && nm.wifi.backend == "iwd");

  enabled = attrs: attrNames (filterAttrs (_: id) attrs);
in {
  # Two associating the same card fight over it, and iwd's own assertion only
  # catches the one spelling of that (networking.wireless.enable), not the
  # per-interface supplicant attrset.
  testOneDaemonAssociatesTheCard = {
    expr = length (enabled {
      networkmanager = nm.enable;
      wpa_supplicant = on.networking.wireless.enable || on.networking.supplicant != {};
      iwd = iwdAlone;
    });
    expected = 1;
  };

  # Likewise for addresses: iwd's DHCP racing networkd's for the same card
  # works right up until it doesn't.
  testOneDaemonAddressesTheCard = {
    expr = length (enabled {
      networkmanager = nm.enable;
      iwd = iwdAlone && (iwd.settings.General.EnableNetworkConfiguration or false);
      networkd = any (n: any (hasPrefix "wl") (toList (n.matchConfig.Name or []))
                         && (n.networkConfig.DHCP or "no") != "no")
                     (attrValues on.systemd.network.networks);
    });
    expected = 1;
  };
}
