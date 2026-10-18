# soba -- my workbench pc

{ self, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  modules = {
    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "ca" ];
      hardware = [
        "cpu/intel"
        "gpu/nvidia/pascal"
        "audio"
        "ssd"
        "bluetooth"
        "wifi"  # Netgear A8000 USB stick (mt7921u)
      ];
    };

    wm = {
      desktop = "hyprland";
      plymouth = {
        enable = true;
        seamless = true;
      };
      hyprland = {
        monitors = [
          { output = "HDMI-A-1";
            primary = true;
            # Is usually hooked up to a small 1024x768 monitor.
            scale = 1.333333; }
          { }  # Adapt to any monitors hooked up to this
        ];
      };
    };

    apps = {
      term.default = "foot";
      term.foot = {
        enable = true;
        fontSize = 24;
      };
      flatpak.enable = true;
      rofi.enable = true;
      thunar.enable = true;
      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
    };
    games.steam.enable = true;
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
    # Tapping power button should do nothing
    services.logind.settings.Login.HandlePowerKey = "ignore";

    environment.systemPackages = with pkgs; [
      freac
    ];
  };

  hardware = { ... }: {
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

      "/media/nas" = {
        device = "nas0.lan:/mnt/nas/users/hlissner/files";
        fsType = "nfs";
        options = [ "noauto" "nofail" "noatime" "nfsvers=4.2" "x-systemd.automount" "x-systemd.idle-timeout=600" ];
      };
    };
    swapDevices = [];
  };
}
