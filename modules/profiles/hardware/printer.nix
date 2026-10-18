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

  # Watch for printers
  (mkIf (any (s: hasPrefix "printer" s) hardware
         && config.services.ipp-usb.enable
         && config.hardware.printers.ensurePrinters != []) {
    systemd.services.cups.serviceConfig.ExecStartPost = mkForce [];
    systemd.services.ensure-printers = {
      description = "Provision CUPS queues once ipp-usb has the printer";
      wantedBy = [ "ipp-usb.service" ];
      after = [ "cups.service" "ipp-usb.service" ];
      requires = [ "cups.service" ];
      path = [ pkgs.cups ];
      serviceConfig.Type = "oneshot";
      script = ''
        for _ in $(seq 60); do
          (exec 3<>/dev/tcp/localhost/60000) 2>/dev/null && break
          sleep 1
        done
        ${config.systemd.services.cups.postStart}
      '';
    };
  })
]
