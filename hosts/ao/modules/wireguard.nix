{ config, lib, pkgs, ... }:

# https://www.zahradnik.io/wireguard-a-vpn-with-real-world-usage-in-mind/
# https://www.wireguardconfig.com/
# https://github.com/ryantm/agenix/blob/main/modules/age.nix
# https://github.com/NixOS/nixos-org-configurations/tree/master/modules
{
  networking = {
    firewall.allowedUDPPorts = [
      # 51820
      51821
    ];
    nat.enable = true;
    nat.externalInterface = "enp0s10";
    nat.internalInterfaces = [
      # "private"
      "servers"
    ];
    firewall.interfaces = {
      # private.allowedTCPPorts = [ 22 443 ];
      servers.allowedTCPPorts = [ 22 3100 ];
    };
    wireguard.interfaces = {
      # private = {
      #   ips = [ "10.0.0.1/16" ];
      #   listenPort = 51820;
      #   privateKeyFile = config.age.secrets.wireguard.path;
      #   peers = [
      #     # { # kuro
      #     #   publicKey = "";
      #     #   allowedIPs = [ "10.0.0.2" ];
      #     # }
      #     { # murasaki
      #       publicKey = "";
      #       allowedIPs = [ "10.0.0.3" ];
      #     }
      #     { # shiro
      #       publicKey = "";
      #       allowedIPs = [ "10.0.0.4" ];
      #     }
      #     # { # midori
      #     #   publicKey = "";
      #     #   allowedIPs = [ "10.0.0.5" ];
      #     # }
      #   ];
      # };
      servers = {
        ips = [ "10.1.0.1/16" ];
        listenPort = 51821;
        privateKeyFile = config.age.secrets.wireguard.path;
        peers = [
          # { # aka
          #   publicKey = "...";
          #   allowedIPs = [ "10.1.0.2" ];
          # }
          { # lissner
            publicKey = "T5ddJdeG1XwtpaqVQ9fm4mKO/O/ib8N88j/B4Cxujh0=";
            allowedIPs = [ "10.1.0.10" ];
            endpoint = "172.105.5.140:51821";
          }
          { # doomemacs
            publicKey = "jC/xqAn3qS1HAZ29Xi7Aa3kHxpwm7sunsCxCHSu04Qk=";
            allowedIPs = [ "10.1.0.11" ];
            endpoint = "172.104.152.17:51821";
          }
        ];
      };
    };
  };
}
