# test/nixos/modules/wifi.nix --- tests for modules/profiles/hardware/wifi.nix
#
# The shell probes D-Bus at startup and silently downgrades to a wifi-less
# backend if it finds neither NetworkManager, wpa_supplicant, nor iwd. Nothing
# in a build catches that (the failure is a greyed-out toggle in a settings
# panel) so I test for it myself.

{ evalConfig, lib, ... }:

with lib;
let
  on = evalConfig [{
    modules.profiles.role = "workstation";
    modules.profiles.hardware = [ "wifi" ];
  }];
in {
  # The supplicant attrset is what the profile used to build, one entry per
  # interface. Anything left there means both daemons running for the same
  # card, which iwd's own assertion does not catch.
  testIwdReplacesTheSupplicant = {
    expr = {
      iwd = on.networking.wireless.iwd.enable;
      wpa = on.networking.wireless.enable;
      supplicant = attrNames on.networking.supplicant;
    };
    expected = { iwd = true; wpa = false; supplicant = []; };
  };

  # iwd associates, networkd addresses. Turning iwd's own DHCP on would put it
  # in a race with 30-wireless (role/workstation.nix), whose wl* glob has to
  # keep covering the card whichever name it ends up with.
  testIwdLeavesL3ToNetworkd =
    let wireless = on.systemd.network.networks."30-wireless"; in {
      expr = {
        iwd = on.networking.wireless.iwd.settings.General.EnableNetworkConfiguration;
        match = wireless.matchConfig.Name;
        dhcp = wireless.networkConfig.DHCP;
      };
      expected = { iwd = false; match = "wl*"; dhcp = "yes"; };
    };
}
