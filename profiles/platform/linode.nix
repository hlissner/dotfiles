# 1. Create three (3) disk images:
#    - Installer: 1024mb
#    - Swap: 512mb
#    - NixOS: rest
#
# 2. Boot in rescue mode with:
#    - /dev/sda -> Installer
#    - /dev/sdb -> Swap
#    - /dev/sdc -> NixOS
#
# 3. Once booted into Finnix (step 2) pipe this script to sh:
#      iso=https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso
#      update-ca-certificates
#      wget -O nixos.iso $iso
#      cp nixos.iso /dev/sda
#
# 4. Create two configuration profiles:
#    - Installer
#      - Kernel: Direct Disk
#      - /dev/sda -> NixOS
#      - /dev/sdb -> Swap
#      - /dev/sdc -> Installer
#      - Helpers: distro and auto network helpers = off
#      - Leave others on their defaults
#    - Boot
#      - Kernel: GRUB 2
#      - /dev/sda -> NixOS
#      - /dev/sdb -> Swap
#      - Helpers: distro and auto network helpers = off
#      - Leave others on their defaults
#
# 5. Boot into installer profile.
#
# 6. Generate hardware-configuration.nix
#      sudo su -
#      e2label /dev/sda nixos
#      swaplabel -L swap /dev/sdb
#      mount /dev/disk/by-label/nixos /mnt
#      swapon /dev/disk/by-label/swap
#      nixos-generate-config --root /mnt
#      vim /mnt/etc/nixos/hardware-configuration.nix   # change uuids to labels
#
# 7. Install dotfiles:
#      nix-env -iA nixos.git nixos.nixFlakes
#      mkdir -p /mnt/home/hlissner/.config
#      cd /mnt/home/hlissner/.config
#      git clone https://github.com/hlissner/dotfiles
#      nixos-install --root /mnt --flake .#linode --impure
#
# 8. Reboot into "Boot" profile.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    linode-cli
  ];

  # GRUB
  boot = {
    kernelModules = [];
    # Needed for LISH (part 1)
    kernelParams = [ "console=ttyS0,19200n8" ];
    extraModulePackages = [];
    initrd = {
      availableKernelModules = [ "virtio_pci" "ahci" "sd_mod" ];
      kernelModules = [];
    };
    loader = {
      timeout = 10;
      grub = {
        enable = true;
        version = 2;
        device = "/dev/sda";
        copyKernels = true;
        fsIdentifier = "provided";
        splashImage = null;
        # Needed for LISH (part 2)
        extraConfig = ''
          serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
          terminal_input serial;
          terminal_output serial
        '';
        # GRUB will complain about blocklists when trying to install grub on a
        # partition-less disk. This tells it to ignore the warning and carry on.
        forceInstall = true;
      };
      # Disable globals
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };
  };

  hardware.cpu.amd.updateMicrocode = mkDefault true;

  networking = {
    enableIPv6 = true;
    tempAddresses = "disabled";
    usePredictableInterfaceNames = false;
    interfaces.eth0 = {
      tempAddress = "disabled";
      useDHCP = true;
    };
  };

  services.gemuGuest.enable = true;

  fileSystems."/" = {
    device = "/dev/sda";
    fsType = "ext4";
  };
  swapDevices = [ { device = "/dev/sdb"; } ];
}
