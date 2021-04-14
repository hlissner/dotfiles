{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [ "ohci_pci" "ehci_pci" "ahci" "firewire_ohci" "usb_storage" "usbhid" "sd_mod" "sr_mod" "sdhci_pci" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" "wl" ];
    extraModulePackages = [];
  };

  ## CPU
  nix.maxJobs = lib.mkDefault 2;
  powerManagement.cpuFreqGovernor = "ondemand";

  ## Harddrives
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
    "/usr/drive" = {
      device = "kiiro:/volume1/homes/hlissner/Drive/backup/ao";
      fsType = "nfs";
      options = [
        "nofail" "noauto" "noatime" "x-systemd.automount" "x-systemd.idle-timeout=5min"
        "nodev" "nosuid" "noexec"
      ];
    };
  };
  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];
}
