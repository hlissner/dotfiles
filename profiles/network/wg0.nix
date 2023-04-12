# wg0 -- homelab VPN

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  networking.firewall.allowedUDPPorts = [ 51820 ];

  age.secrets.wg0PrivateKey.owner = "systemd-network";

  systemd.network = {
    enable = true;
    netdevs = {
      "10-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1500";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg0PrivateKey.path;
          ListenPort = "51820";
        };
        wireguardPeers = [{
          wireguardPeerConfig = {
            PublicKey = "kuv6kPygJbjcAbhogEst5m8XyKz9pn0XgyR7EcnveAU=";
            AllowedIPs = [ "10.0.0.0/24" ];
            Endpoint = "0.he.nrik.dev:51820";
          };
        }];
      };
    };
    networks.wg0 = {
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
}
