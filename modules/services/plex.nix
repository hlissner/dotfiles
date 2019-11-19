{ config, pkgs, ... }:

{
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  services.transmission.enable = true;
}
