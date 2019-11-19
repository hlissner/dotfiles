{ config, pkgs, ... }:

{
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  services.transmission = {
    enable = true;
    settings.rpc-whitelist = "127.0.0.1,192.168.*.*";
  };
  networking.firewall.allowedTCPPorts = [ 9091 51413 ];
}
