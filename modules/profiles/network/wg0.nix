# modules/profiles/network/wg0 -- homelab VPN

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "wg0" config.modules.profiles.networks) (mkMerge [
  {
    networking.firewall.allowedUDPPorts = [ 51820 ];

    age.secrets.wg0PrivateKey.owner = "systemd-network";

    systemd.network = {
      enable = true;
      netdevs."90-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg0PrivateKey.path;
          ListenPort = "51820";
        };
        wireguardPeers = [{
          PublicKey = "kuv6kPygJbjcAbhogEst5m8XyKz9pn0XgyR7EcnveAU=";
          AllowedIPs = [ "10.0.0.0/24" ];
          Endpoint = "0.home.lissner.net:51820";
        }];
      };
      networks.wg0 = {
        # address = ...;
        matchConfig.Name = "wg0";
        DHCP = "no";
        domains = [ "home.lissner.net" ];
        networkConfig = {
          DNSSEC = false;
          DNSDefaultRoute = false;
        };
      };
    };

    systemd.network.wait-online.ignoredInterfaces = [ "wg0" ];
    boot.initrd.systemd.network.wait-online.ignoredInterfaces = [ "wg0" ];
  }

  # ...
])
