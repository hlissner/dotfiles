# profiles/hardware/wifi.nix --- wifi via iwd
#
# I chose iwd back when my shell at the time didn't support wpa_supplicant;
# Noctalia speaks NetworkManager, wpa_supplicant and iwd natively, so there's no
# reason to move. Enterprise (802.1X) networks are NetworkManager-only in its
# UI, which I'm fine managing by hand.

{ self, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with self.lib;
let
  # Power save on an idle wifi link means delays on every keystroke over ssh.
  # Turn it off on AC power.
  powersave = pkgs.writeShellScript "wifi-powersave" ''
    mode=on
    mains=
    for p in /sys/class/power_supply/*; do
      [[ -r $p/type && $(<$p/type) == Mains ]] || continue
      mains=1
      [[ $(<$p/online) == 1 ]] && mode=off
    done
    [[ -z $mains ]] && mode=off
    for d in /sys/class/net/wl*; do
      [[ -e $d ]] && ${pkgs.iw}/bin/iw dev ''${d##*/} set power_save $mode
    done
  '';
in
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

  environment.systemPackages = [ pkgs.iw ];

  # mac80211 keeps power_save on the netdev across associations, so set it the
  # moment the interface appears (before iwd gets to it).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${powersave}"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${powersave}"
  '';
}
