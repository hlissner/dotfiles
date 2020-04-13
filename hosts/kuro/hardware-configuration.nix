{ config, pkgs, lib, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  ## CPU
  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.intel.updateMicrocode = true;

  ## SSDs
  services.fstrim.enable = true;

  ## Ergodox
  my.packages = [ pkgs.teensy-loader-cli ];
  my.alias.teensyload = "sudo teensy-loader-cli -w -v --mcu=atmega32u4";
  # Make ralt the compose key, so ralt+a+a = å or ralt+o+/ = ø
  services.xserver.xkbOptions = "compose:ralt";

  ## GPU
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  # Respect XDG conventions, damn it!
  environment.systemPackages = with pkgs; [
    (writeScriptBin "nvidia-settings" ''
      #!${stdenv.shell}
      mkdir -p "$XDG_CONFIG_HOME/nvidia"
      exec ${config.boot.kernelPackages.nvidia_x11.settings}/bin/nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"
    '')
  ];

  ## Tablet
  # For my intuos4 pro. Doesn't work for cintiqs.
  services.xserver.wacom.enable = true;
  # TODO Move this to udev
  # system.userActivationScripts.wacom.text = ''
  #   # lock tablet to main display
  #   if xinput list --id-only "Wacom Intuos Pro S Pen stylus" 2>&1 >/dev/null; then
  #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen stylus") DVI-I-1
  #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen eraser") DVI-I-1
  #     xinput map-to-output $(xinput list --id-only "Wacom Intuos Pro S Pen cursor") DVI-I-1
  #   fi
  # '';

  ### Harddrives
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
    "/mnt/projects" = {
      device = "/dev/disk/by-label/projects";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/mnt/archive" = {
      device = "/dev/disk/by-label/archive";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/mnt/local" = {
      device = "/dev/disk/by-label/local";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
}
