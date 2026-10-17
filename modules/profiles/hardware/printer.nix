# profiles/hardware/printer
#
# Printers exist because there isn't enough despair in the world.

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "printer" s) hardware) {
    environment.systemPackages = with pkgs;
      optional (config.modules.profiles.role == "workstation") system-config-printer;

    services.printing = {
      enable = true;
      startWhenNeeded = mkDefault true;
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
      startWhenNeeded = false;
      browsing = true;
    };
    services.avahi = {
      enable = true;
      openFirewall = true;
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
