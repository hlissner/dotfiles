{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/scan/not-detected.nix" ];

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
    initrd.kernelModules = [];
    extraModulePackages = [];
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      # HACK Disables fixes for spectre, meltdown, L1TF and a number of CPU
      #      vulnerabilities. Don't copy this blindly! And especially not for
      #      mission critical or server/headless builds exposed to the world.
      "mitigations=off"
    ];

    # Refuse ICMP echo requests on my desktop/laptop; nobody has any business
    # pinging them, unlike my servers.
    kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  };

  # Modules
  modules.hardware = {
    audio.enable = true;
    ergodox.enable = true;
    fs = {
      enable = true;
      ssd.enable = true;
    };
    nvidia.enable = true;
    sensors.enable = true;
  };

  # CPU
  nix.settings.max-jobs = lib.mkDefault 16;
  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.amd.updateMicrocode = true;

  # Displays
  services.xserver = {
    # This must be done manually to ensure my screen spaces are arranged exactly
    # as I need them to be *and* the correct monitor is "primary". Using
    # xrandrHeads does not work.
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
    "/usr/drive" = {
      device = "kiiro:/volume1/homes/hlissner/Drive";
      fsType = "nfs";
      options = [
        "nofail" "noauto" "noatime" "x-systemd.automount" "x-systemd.idle-timeout=5min"
        "nodev" "nosuid" "noexec"
      ];
    };
    "/usr/store" = {
      device = "/dev/disk/by-label/store";
      fsType = "ext4";
      options = [
        "noauto" "noatime" "x-systemd.automount" "x-systemd.idle-timeout=5min"
        "nodev" "nosuid" "noexec"
      ];
    };
  };
  swapDevices = [];
}
