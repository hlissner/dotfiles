{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  networking = {
    firewall.allowedUDPPorts = [ 51820 ];
    wireguard.interfaces = {
      wg-homelab = {
        # ips = [ cfg.ip ];
        # privateKeyFile = cfg.privateKeyFile;
        listenPort = 51820;
        postSetup = ''
          ${pkgs.systemd}/bin/resolvectl dns    wg-homelab 10.0.0.1
          ${pkgs.systemd}/bin/resolvectl domain wg-homelab home.lissner.net
        '';
        peers = [
          {
            publicKey = "kuv6kPygJbjcAbhogEst5m8XyKz9pn0XgyR7EcnveAU=";
            allowedIPs = [ "10.0.0.0/24" ];
            endpoint = "0.he.nrik.dev:51820";
            # Wireguard will only resolve a non-IP endpoint once, at startup.
            # Since my IP changes once in a while, reload the interface every
            # 5 minutes, just in case.
            dynamicEndpointRefreshSeconds = 600;  # every 5min
          }
        ];
      };
    };
  };
}
