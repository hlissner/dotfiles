# profiles/role/workstation.nix
#
# TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (config.modules.profiles.role == "workstation") (mkMerge [
  {
    boot = {
      # HACK I used to disable mitigations for spectre, meltdown, L1TF,
      #   retbleed, and other CPU vulnerabilities for a marginal performance
      #   gain on non-servers, but it really makes little to no difference on
      #   modern CPUs. It may still be worth it on older Xeons and the like (on
      #   workstations) though. I've preserved this in comments for future
      #   reference.
      #
      #   DO NOT COPY AND UNCOMMENT IT BLINDLY! If you're looking for
      #   optimizations, these aren't the droids you're looking for!
      # kernelParams = [ "mitigations=off" ];

      loader = {
        # I'm not a big fan of Grub, so if it's not in use...
        systemd-boot.enable = mkDefault true;
        # For much quicker boot up to NixOS. I can use `systemctl reboot
        # --boot-loader-entry=X` instead.
        timeout = mkDefault 1;
      };

      # For a truly silent boot!
      # kernelParams = [
      #   "quiet"
      #   "splash"
      #   "udev.log_level=3"
      # ];
      # consoleLogLevel = 0;
      # initrd.verbose = false;

      # Common kernels across workstations
      initrd.availableKernelModules = [
        "xhci_pci"     # USB 3.0
        "usb_storage"  # USB mass storage devices
        "usbhid"       # USB human interface devices
        "ahci"         # SATA devices on modern AHCI controllers
        "sd_mod"       # SCSI, SATA, and IDE devices
      ];

      # The default maximum is too low, which starves IO hungry apps.
      kernel.sysctl."fs.inotify.max_user_watches" = 524288;
    };

    # TODO ...
    powerManagement.cpuFreqGovernor = mkDefault "performance";

    # Use systemd-{network,resolve}d; a more unified networking backend that's
    # easier to reconfigure downstream, especially where split-DNS setups (e.g.
    # VPNs) are concerned.
    networking = {
      useDHCP = false;
      useNetworkd = true;
    };
    systemd = {
      network = {
        # Automatically manage all wired/wireless interfaces.
        networks = {
          "30-wired" = {
            enable = true;
            name = "en*";
            networkConfig.DHCP = "yes";
            networkConfig.IPv6PrivacyExtensions = "kernel";
            linkConfig.RequiredForOnline = "no"; # don't hang at boot (if dc'ed)
            dhcpV4Config.RouteMetric = 1024;
          };
          "30-wireless" = {
            enable = true;
            name = "wl*";
            networkConfig.DHCP = "yes";
            networkConfig.IPv6PrivacyExtensions = "kernel";
            linkConfig.RequiredForOnline = "no"; # don't hang at boot (if dc'ed)
            dhcpV4Config.RouteMetric = 2048;     # prefer wired
          };
        };

        # systemd-networkd-wait-online waits forever for *all* interfaces to be
        # online before passing; which is unlikely to ever happen.
        wait-online = {
          anyInterface = true;
          timeout = 30;

          # The anyInterface setting is still finnicky for some networks, so I
          # simply turn off the whole check altogether.
          enable = false;
        };
      };
    };
    boot.initrd.systemd.network.wait-online = {
      anyInterface = true;
      timeout = 10;
    };

    modules.xdg.ssh.enable = true;

    # See systemd/systemd#10579
    services.resolved.dnssec = "false";
  }

  (mkIf config.modules.services.ssh.enable {
    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
  })

  # ...
])
