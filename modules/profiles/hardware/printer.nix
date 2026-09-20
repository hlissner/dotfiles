# profiles/hardware/printer
#
# Printers exist because there isn't enough despair in the world.

{ hey, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "printer" s) hardware) {
    environment.systemPackages = with pkgs; [
      system-config-printer
    ];

    services.printing = {
      enable = true;
      startWhenNeeded = true;
      # logLevel = "debug";
    };
  })

  (mkIf (elem "printer/wireless" hardware) {
    services.avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
  })

  (mkIf (any (s: hasPrefix "printer/share" s) hardware) {
    services.printing = {
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      defaultShared = true;
    };
    services.avahi = {
      publish = {
        enable = true;
        userServices = true;
      };
    };
    networking.firewall = mkIf config.services.printing.enable {
      allowedUDPPorts = [ 631 ];
      allowedTCPPorts = [ 631 ];
    };
  })
]
