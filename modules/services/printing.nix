# modules/services/printing.nix
#
# Share the suffering.

{ hey, lib, config, options, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.printing;
in {
  options.modules.services.printing = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    services.printing = {
      browsing = true;
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      defaultShared = true;
    };

    networking.firewall = {
      allowedUDPPorts = [ 631 ];
      allowedTCPPorts = [ 631 ];
    };
  };
}
