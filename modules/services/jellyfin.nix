# Finally, a decent open alternative to Plex!

{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.jellyfin = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.jellyfin.enable {
    services.jellyfin.enable = true;

    networking.firewall = {
      allowedTCPPorts = [ 8096 ];
      allowedUDPPorts = [ 8096 ];
    };

    my.user.extraGroups = [ "jellyfin" ];
  };
}
