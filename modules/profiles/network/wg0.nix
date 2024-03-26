# modules/profiles/network/wg0 -- homelab VPN

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
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
          MTUBytes = "1420";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg0PrivateKey.path;
          ListenPort = "51820";
        };
        wireguardPeers = [{
          wireguardPeerConfig = {
            PublicKey = "kuv6kPygJbjcAbhogEst5m8XyKz9pn0XgyR7EcnveAU=";
            AllowedIPs = [ "10.0.0.0/8" ];
            Endpoint = "0.home.lissner.net:51820";
          };
        }];
      };
      networks."90-wg0" = {
        # address = ...;
        matchConfig.Name = "wg0";
        DHCP = "no";
        dns = [ "10.0.0.1" ];
        domains = [ "home.lissner.net" "git.henrik.io" ];
        networkConfig = {
          DNSSEC = false;
          DNSDefaultRoute = false;
        };
        routes = [{
          routeConfig = {
            Gateway = "10.0.0.1";
            GatewayOnLink = true;
            Destination = "10.0.0.0/24";
          };
        }];
      };
    };

    systemd.network.wait-online.ignoredInterfaces = [ "wg0" ];
    boot.initrd.systemd.network.wait-online.ignoredInterfaces = [ "wg0" ];
  }

  # ...
])
