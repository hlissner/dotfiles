{ self, lib, profiles, ... }:

{
  system = "x86_64-linux";

  profiles = with profiles; [
    hardware.common.cpu.amd
  ];

  config = { config, pkgs, lib, modulesPath, ...}: {
    imports = [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

    user.name = "nixos";

    # Set up filesystems according to Linode preference:
    fileSystems."/" = {
      device = "/dev/sda";
      fsType = "ext4";
      autoResize = true;
    };
    swapDevices = [{ device = "/dev/sdb"; }];

    # Enable LISH and Linode booting w/ GRUB
    boot = {
      initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_scsi"
        "ahci"
        "sd_mod"
      ];
      growPartition = true;
      kernelParams = [ "console=ttyS0,19200n8" ];
      loader = {
        timeout = lib.mkForce 10; # Increase timeout to allow LISH connection:
        grub = {
          enable = true;
          version = 2;
          forceInstall = true;
          device = "nodev";
          fsIdentifier = "label";
          # Allow serial connection for GRUB to be able to use LISH:
          extraConfig = ''
            serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
            terminal_input serial;
            terminal_output serial
          '';
          extraInstallCommands = ''
            ln -fs /boot/grub /boot/grub2
          '';
          splashImage = null;
        };
      };
    };

    # Install diagnostic tools for Linode support:
    environment.systemPackages = with pkgs; [
      inetutils
      mtr
      sysstat
      linode-cli
    ];

    networking = {
      enableIPv6 = true;
      tempAddresses = "disabled";
      useDHCP = true;
      usePredictableInterfaceNames = false;
      interfaces.eth0 = {
        tempAddress = "disabled";
        useDHCP = true;
      };
    };

    services.qemuGuest.enable = true;
  };
}

# $ nix build .#nixosConfigurations.linode.config.system.build.isoImage
# or
# $ hey rebuild --host installer build-iso
