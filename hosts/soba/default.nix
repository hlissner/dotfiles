# htpc -- my HTPC (shocker)

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  imports = [
    hey.modules.nixos-hardware.common-cpu-intel-skylake
    hey.modules.nixos-hardware.common-gpu-nvidia-pascal
  ];

  modules = {
    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "ca" ];
      hardware = [
        "cpu/intel"
        "gpu/nvidia"
        "audio"
        "ssd"
        "bluetooth"
      ];
    };

    hyprland = rec {
      enable = true;
      monitors = [
        { output = "HDMI-A-2";
          mode = "3840x2160@120";
          primary = true; }
      ];
    };

    apps = {
      term.default = "foot";
      term.foot.enable = true;
      rofi.enable = true;
      thunar.enable = true;
      steam.enable = true;
      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
    };
    shell = {
      git.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    services = {
      ssh.enable = true;
      flatpak.enable = true;
    };
    system = {
      utils.enable = true;
    };
  };

  ## local config
  config = { config, pkgs, ... }: {
    # Tapping power button should do nothing
    services.logind.settings.Login.HandlePowerKey = "ignore";

    environment.systemPackages = with pkgs; [
      freac
    ];
    services.udisks2.enable = true;
  };

  hardware = { ... }: {
    # networking.interfaces.eno1.useDHCP = true;

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
        options = [ "noatime" "errors=remount-ro" ];
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
    };
    swapDevices = [];
  };
}
