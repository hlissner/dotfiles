{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  boot.kernelParams = [
    # HACK Disables fixes for spectre, meltdown, L1TF and a number of CPU
    #   vulnerabilities for a slight performance boost. Don't copy this blindly!
    #   And especially not for mission critical or server/headless builds
    #   exposed to the world.
    "mitigations=off"
  ];

  # Refuse ICMP echo requests on on desktops/laptops; nobody has any business
  # pinging them.
  boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = 1;

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
  # Comment out as appropriate
  hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Storage
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
    "/home" = {
      device = "/dev/disk/by-label/home";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
  swapDevices = [ "/dev/disk/by-label/swap" ];
}
