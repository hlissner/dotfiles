# test/nixos/modules/wifi.nix --- tests for modules/profiles/hardware/wifi.nix
#
# DMS probes D-Bus at startup and silently downgrades to a wifi-less backend if
# it finds neither NetworkManager, ConnMan, nor iwd. Nothing in a build catches
# that (the failure is a greyed-out toggle in a settings panel) so I test for it
# myself.

{ evalConfig, lib, ... }:

with lib;
let
  off = evalConfig [];

  on = evalConfig [{
    modules.profiles.hardware = [ "wifi" ];
  }];

  # See 30-wireless in role/workstation.nix
  workstation = evalConfig [{
    modules.profiles.role = "workstation";
    modules.profiles.hardware = [ "wifi" ];
  }];
in {
  testProfileIsOptIn = {
    expr = off.networking.wireless.iwd.enable;
    expected = false;
  };

  testProfileEnablesIwd = {
    expr = on.networking.wireless.iwd.enable;
    expected = true;
  };

  ## The daemon swap

  # The supplicant attrset is what the profile used to build, one entry per
  # interface. Anything left here means both daemons would be running for the
  # same card, which iwd's own assertion does not catch.
  testSupplicantIsGone = {
    expr = attrNames on.networking.supplicant;
    expected = [];
  };

  testWpaSupplicantIsNotEnabled = {
    expr = on.networking.wireless.enable;
    expected = false;
  };

  ## The split with networkd

  # iwd associates, networkd addresses. Turning this on would put iwd's DHCP
  # client in a race with 30-wireless (role/workstation.nix).
  testIwdLeavesL3ToNetworkd = {
    expr = on.networking.wireless.iwd.settings.General.EnableNetworkConfiguration;
    expected = false;
  };

  # role/workstation.nix matches wl*, so the interface still has to be one.
  testNetworkdStillAddressesWireless = {
    expr = workstation.systemd.network.networks."30-wireless".networkConfig.DHCP;
    expected = "yes";
  };

  ## Interface naming
  #
  # The card is wlan0, not wlp2s0: nixpkgs' 80-iwd.link sets NamePolicy to "keep
  # kernel" and outranks 99-default.link. That's left alone on purpose (see the
  # module), so these pin the two assumptions the literal wlan0 below rests on.

  # If nixpkgs ever drops or widens this, the card gets its path-based name back
  # and the ignoredInterfaces entry stops matching anything -- silently.
  testIwdKeepsKernelNaming = {
    expr = on.systemd.network.links."80-iwd".linkConfig.NamePolicy;
    expected = "keep kernel";
  };

  testWlanLinkIsStillScopedToWlan = {
    expr = on.systemd.network.links."80-iwd".matchConfig.Type;
    expected = "wlan";
  };

  # The glob is what makes the naming question moot for addressing: it covers
  # wlan0 and wlp2s0 alike, so 30-wireless does not care which one won.
  testNetworkdMatchesEitherName = {
    expr = workstation.systemd.network.networks."30-wireless".matchConfig.Name;
    expected = "wl*";
  };

  # Inert while role/workstation.nix disables wait-online, but it has to be right
  # for when that flips back. Literal names here; ignoredInterfaces takes no globs.
  testWirelessIsIgnoredByWaitOnline = {
    expr = on.systemd.network.wait-online.ignoredInterfaces;
    expected = [ "wlan0" ];
  };
}
