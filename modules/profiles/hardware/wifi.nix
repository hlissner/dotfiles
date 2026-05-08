# profiles/hardware/wifi.nix --- TODO

{ hey, lib, options, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let interfaces = config.networking.wireless.interfaces;
    isWorkstation = config.modules.profiles.role == "workstation";
in mkIf (elem "wifi" config.modules.profiles.hardware) {
  environment.systemPackages = with pkgs; [
    networkmanager
    iwd
    networkmanagerapplet
  ];

  networking = mkIf isWorkstation {
    useDHCP = mkForce false;
    useNetworkd = mkForce false;
    wireless = {
      enable = mkForce false;
      iwd = {
        enable = true;
        settings = {
          General = {
            # NetworkManager owns DHCP/routes while using iwd as the Wi-Fi backend.
            EnableNetworkConfiguration = false;
            RoamRetryInterval = 30;
          };
          Network = {
            EnableIPv6 = true;
            RoutePriorityOffset = 300;
          };
          Settings.AutoConnect = true;
        };
      };
    };
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      dns = "systemd-resolved";
      unmanaged = [
        "interface-name:tailscale*"
        "interface-name:docker*"
        "interface-name:br-*"
        "interface-name:virbr*"
        "interface-name:vboxnet*"
        "interface-name:waydroid*"
        "interface-name:wg*"
        "interface-name:rndis*"
        "type:bridge"
      ];
      settings = {
        device."wifi.scan-rand-mac-address" = "yes";
        connection."wifi.cloned-mac-address" = "stable";
        connectivity.enabled = false;
      };
    };
  };

  services.resolved = mkIf isWorkstation {
    enable = true;
    dnssec = "false";
  };

  systemd.services.NetworkManager-wait-online.enable = mkIf isWorkstation false;
  systemd.network.wait-online.enable = mkIf isWorkstation false;
  boot.initrd.systemd.network.wait-online.ignoredInterfaces = interfaces;
}
