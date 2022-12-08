{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.profiles.workstation;
in {
  options.profiles.workstation = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    boot = {
      kernelParams = [
        # HACK Disables fixes for spectre, meltdown, L1TF and a number of CPU
        #      vulnerabilities. Don't copy this blindly! And especially not for
        #      mission critical or server/headless builds exposed to the world.
        "mitigations=off"
      ];

      # Refuse ICMP echo requests on my workstations; nobody has any business
      # pinging them, unlike my servers.
      kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = 1;

      # I'm not a big fan of Grub.
      loader.systemd-boot.enable = mkDefault true;
    };

    # TODO ...
    powerManagement.cpuFreqGovernor = mkDefault "performance";

    # Ensure we always have nmtui/nmcli
    networking.networkmanager.enable = true;
    user.extraGroups = [ "networkmanager" ];

    # For redshift, mainly
    location = (if config.time.timeZone == "America/Toronto" then {
      latitude = 43.70011;
      longitude = -79.4163;
    } else if config.time.timeZone == "Europe/Copenhagen" then {
      latitude = 55.88;
      longitude = 12.5;
    } else {});

    # Block garbage (ads, trackers, etc) if this is a workstation system
    # TODO Offload to OPNSense/PiHole
    networking.extraHosts =
      let blocklist = fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts;
      in optionalString config.services.xserver.enable (readFile blocklist);

    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
  };
}
