# htpc -- my HTPC (shocker)

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  imports = [
    hey.modules.nixos-hardware.common-cpu-intel
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
        "audio/realtime"
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

      ## Extra
      flatpak.enable = true;
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
    };
    system = {
      utils.enable = true;
    };
  };

  ## local config
  config = { config, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      flex-launcher
    ];

    services.jellyfin = {
      enable = true;
      openFirewall = true;
      dataDir = "/home/${config.user.name}/jellyfin";
      user = config.user.name;
    };

    hey.hooks."on-started"."10-flex-launcher" = ''
      hey.do flex-launcher
    '';
  };

  hardware = { config, ... }: {
    # GTX 960 (Maxwell 2.0, GM206) requires v580
    hardware.nvidia = {
      open = false;  # Turing and later only
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };

    # Skylake = gen9, the generic compute module requires gen12+
    hardware.intelgpu.computeRuntime = "legacy";

    services.logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
    };

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
