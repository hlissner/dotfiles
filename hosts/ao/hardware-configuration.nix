{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [ "ohci_pci" "ehci_pci" "ahci" "firewire_ohci" "usb_storage" "usbhid" "sd_mod" "sr_mod" "sdhci_pci" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" "wl" ];
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  };

  ## Modules
  modules.hardware.fs = {
    enable = true;
    ssd.enable = true;
  };

  # Don't turn off/sleep when closing the lid of the laptop.
  services.logind.lidSwitch = "ignore";

  ## CPU
  nix.settings.max-jobs = lib.mkDefault 2;
  powerManagement.cpuFreqGovernor = "ondemand";
  hardware.cpu.intel.updateMicrocode = true;

  ## Networking
  networking.interfaces.enp0s10.useDHCP = true;

  ## Harddrives
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };
    "/backup" = {
      device = "/dev/mapper/backup";
      fsType = "ext4";
      options = [ "noatime" "nofail" ];
    };
  };
  boot.initrd.luks.devices.backup.device = "/dev/disk/by-uuid/8839e98a-b1d1-441f-bac3-47dc092685c2";
  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];
}
