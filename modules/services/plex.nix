{ config, pkgs, ... }:

{
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
  };

  services.transmission.enable = true;
  networking.firewall.allowedTCPPorts = [ 9091 ];
}
