{ config, lib, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  boot.initrd.availableKernelModules = [ "ohci_pci" "ehci_pci" "ahci" "firewire_ohci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  ## CPU
  nix.maxJobs = lib.mkDefault 2;

  ## Networking
  networking.useDHCP = false;
  networking.interfaces.enp0s10.useDHCP = true;

  ## Harddrives
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/nixos";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/boot";
      fsType = "vfat";
    };
  };
  swapDevices = [{ device = "/dev/disk/by-uuid/swap"; }];
}
