# profiles/hardware/printer
#
# Printers exist because there isn't enough despair in the world.

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
let hardware = config.modules.profiles.hardware;
    publishAll = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
    };
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
      nssmdns4 = true;
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
      settings.publish = publishAll;
    };
    networking.firewall = mkIf config.services.printing.enable {
      allowedUDPPorts = [ 631 ];
      allowedTCPPorts = [ 631 ];
    };
  })

  # nixpkgs' ipp-usb module still speaks pre-RFC42 services.avahi.publish.*,
  # so avahi warns about it on every eval. Null those and say the same thing in
  # the new dialect, until upstream catches up.
  (mkIf config.services.ipp-usb.enable {
    services.avahi = {
      publish = { enable = mkForce null; userServices = mkForce null; };
      settings.publish = publishAll;
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
