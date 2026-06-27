# htpc -- my HTPC (shocker)

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  imports = [
    hey.modules.nixos-hardware.common-cpu-intel-skylake
    hey.modules.nixos-hardware.common-gpu-nvidia-maxwell
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

    desktop = {
      hyprland = rec {
        enable = true;
        monitors = [
          { output = "HDMI-A-2";
            mode = "3840x2160@120";
            primary = true; }
        ];
      };
      term.default = "foot";
      term.foot.enable = true;

      ## Extra
      apps.rofi.enable = true;
      apps.thunar.enable = true;
      apps.steam.enable = true;

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
      fs.enable = true;
    };
  };

  ## local config
  config = { config, ... }: {
    environment.systemPackages = with pkgs; [
      flex-launcher
    ];

    services.jellyfin = {
      enable = true;
      openFirewall = true;
      dataDir = "/home/${config.user.name}/jellyfin";
      user = config.user.name;
    };

    hey.hooks.onStartup."10-flex-launcher" = ''
      hey.do flex-launcher
    '';
  };

  hardware = { ... }: {
    networking.interfaces.eno1.useDHCP = true;

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
