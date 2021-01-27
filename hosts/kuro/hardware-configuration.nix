{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/scan/not-detected.nix" ];

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
    initrd.kernelModules = [];
    extraModulePackages = [];
    kernelModules = [
      "kvm-amd"
      "asix"  # REVIEW Remove me when 5.9 kernel is available
    ];
    kernelParams = [
      # HACK Disables fixes for spectre, meltdown, L1TF and a number of CPU
      #      vulnerabilities. This is not a good idea for mission critical or
      #      server/headless builds, but on my lonely home system I prioritize
      #      raw performance over security.  The gains are minor.
      "mitigations=off"
      # Limit ZFS cache to 8gb. Sure, this system has 64gb, but I don't want
      # this biting me when I'm running multiple VMs.
      "zfs.zfs_arc_max=8589934592"
    ];
  };

  # CPU
  nix.maxJobs = lib.mkDefault 16;
  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.amd.updateMicrocode = true;

  # Displays
  services.xserver = {
    monitorSection = ''
      VendorName  "Unknown"
      ModelName   "DELL U2515H"
      HorizSync   30.0 - 113.0
      VertRefresh 56.0 - 86.0
      Option      "DPMS"
    '';
    screenSection = ''
      Option "metamodes" "HDMI-0: nvidia-auto-select +1920+0, DVI-I-1: nvidia-auto-select +0+180, DVI-D-0: nvidia-auto-select +4480+180"
      Option "SLI" "Off"
      Option "MultiGPU" "Off"
      Option "BaseMosaic" "off"
      Option "Stereo" "0"
      Option "nvidiaXineramaInfoOrder" "DFP-1"
    '';
  };

  # Storage
  networking.hostId = "edd9f26b";  # required by zfs
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
    "/home" = {
      device = "/dev/disk/by-label/home";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/usr/backup" = {
      device = "usr/backup";
      fsType = "zfs";
      options = [ "nofail" ];
    };
    "/usr/media" = {
      device = "usr/media";
      fsType = "zfs";
      options = [ "nofail" ];
    };
    "/usr/local" = {
      device = "usr/local";
      fsType = "zfs";
      options = [ "nofail" ];
    };
    "/usr/share" = {
      device = "usr/share";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  };
  swapDevices = [];
}
