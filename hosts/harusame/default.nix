# Harusame -- my workstation abroad

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  ## Dotfiles modules
  modules = {
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "dk" "ts0" ];
      hardware = [
        "cpu/amd"
        "gpu/nvidia"
        "audio"
        "ssd"
        "ergodox"
        "bluetooth"
      ];
    };

    hyprland = {
      enable = true;
      monitors = [
        { output = "DP-1";
          mode = "1920x1080@60";
          position = "0x0";
          primary = true; }
        { output = "HDMI-A-1";
          mode = "1920x1080@75";
          position = "1920x0"; }
      ];
    };

    apps = {
      term.default = "foot";
      term.foot.enable = true;

      rofi.enable = true;
      steam = {
        enable = true;
        libraryDir = "/media/games/SteamLibrary";
      };
      libreoffice.enable = true;
      godot.enable = true;
      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
      media.cad.enable = true;
      media.daw.enable = true;
      media.graphics.enable = true;
      # media.music.enable = true;
      media.video.enable = true;
      media.video.capture.enable = true;
    };
    dev = {
      cc.enable = true;
    };
    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };
    shell = {
      vaultwarden.enable = true;
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    services = {
      ssh.enable = true;
    };
    system = {
      utils.enable = true;
    };
    # virt.qemu.enable = true;
  };

  ## Local config
  config = { pkgs, ... }: {
    # Tapping power button should do nothing
    services.logind.settings.Login.HandlePowerKey = "ignore";
  };

  ## Hardware config
  hardware = { ... }: {
    boot.supportedFilesystems = [ "ntfs" ];

    networking.interfaces.enp42s0.useDHCP = true;

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
      "/media/games" = {
        device = "/dev/disk/by-label/games";
        fsType = "ntfs";
        options = [ "defaults" "noauto" "nofail" "noatime" "nodev" "exec" "umask=000" "uid=1000" "gid=1000" "x-systemd.automount" ];
      };
    };
    swapDevices = [];
  };
}
