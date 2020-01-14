{ config, lib, pkgs, ... }:

{
  services.transmission = {
    enable = true;
    home = "/data/media/torrents";
    settings = {
      incomplete-dir-enabled = true;
      rpc-whitelist = "127.0.0.1,192.168.*.*";
      rpc-host-whitelist = "*";
      rpc-host-whitelist-enabled = true;
      ratio-limit = 0;
      ratio-limit-enabled = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 51413 ];
    allowedUDPPorts = [ 51413 ];
  };

  my.user.extraGroups = [ "transmission" ];
}
