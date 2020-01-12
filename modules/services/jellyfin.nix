# Finally, a decent open alternative to Plex!

{ config, lib, pkgs, ... }:

{
  services.jellyfin = { enable = true; };

  networking.firewall = {
    allowedTCPPorts = [ 8096 ];
    allowedUDPPorts = [ 8096 ];
  };

  my.user.extraGroups = [ "jellyfin" ];
}
