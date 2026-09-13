# profiles/hardware/wifi.nix --- wifi via iwd
#
# I chose iwd because DMS doesn't support wpa_supplicant (it supports
# NetworkManager, ConnMan, iwd, and bare systemd-networkd). Beyond that, DMS
# displays the WiFi as always off, even if it's functional. Only downside: DMS
# needs Networkmanager for the VPN panel, but that I'm find managing manually.

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
