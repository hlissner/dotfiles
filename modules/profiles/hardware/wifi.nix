# profiles/hardware/wifi.nix --- wifi via iwd
#
# I chose iwd back when DMS didn't support wpa_supplicant; Noctalia speaks
# NetworkManager, wpa_supplicant and iwd natively, so there's no reason to
# move. Enterprise (802.1X) networks are NetworkManager-only in its UI, which
# I'm fine managing by hand.

{ hey, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
mkIf (elem "wifi" config.modules.profiles.hardware) {
  networking.wireless.iwd = {
    enable = true;
    settings = {
      # Leave L3 to networkd
      General.EnableNetworkConfiguration = false;
      Settings.AutoConnect = true;
    };
  };

  # Noop because role/workstation.nix disables wait-online, but kept in case I
  # restore that it later.
  systemd.network.wait-online.ignoredInterfaces = [ "wlan0" ];
}
