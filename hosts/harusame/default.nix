# Harusame -- my workstation abroad

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  ## Dotfiles modules
  modules = {
    theme = {
      active = "autumnal";
      # wallpapers."*".path = ./wallpaper.png;
    };
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "dk" "wg0" ];
      hardware = [
        "cpu/amd"
        "gpu/nvidia"
        "audio"
        "ssd"
        "ergodox"
        "bluetooth"
      ];
    };

    desktop = {
      hyprland = {
        enable = true;
        monitors = [
          { output = "HDMI-0";
            position = "1920x0";
            primary = true; }
          { output = "DP-1";
            mode = "1920x1080@75"; }
        ];
      };
      term.default = "foot";
      term.foot.enable = true;

      apps.rofi.enable = true;
      apps.spotify.enable = true;
      apps.steam = {
        enable = true;
        libraryDir = "/media/games/SteamLibrary";
      };
      apps.godot.enable = true;
      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
      media.cad.enable = true;
      media.daw.enable = true;
      media.graphics.enable = true;
      media.music.enable = true;
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
      fs.enable = true;
    };
    # virt.qemu.enable = true;
  };

  ## Local config
  config = { pkgs, ... }: {
    systemd.network.networks.wg0.address = [ "10.10.0.3/32" ];

    environment.systemPackages = with pkgs; [
      abcde
    ];
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

  ## TODO: Declarative partitioning
  # storage = { ... }: {
  #   disk.sda = {
  #     device = "/dev/nvme0n1";
  #     type = "disk";
  #     content = {
  #       type = "table";
  #       format = "gpt";
  #       partitions = [
  #         {
  #           type = "partition";
  #           name = "ESP";
  #           start = "1MiB";
  #           end = "128MiB";
  #           bootable = true;
  #           content = {
  #             type = "filesystem";
  #             format = "vfat";
  #             mountpoint = "/boot";
  #           };
  #         }
  #         {
  #           name = "nixos";
  #           type = "partition";
  #           start = "128MiB";
  #           end = "200G";
  #           bootable = true;
  #           content = {
  #             type = "filesystem";
  #             format = "ext4";
  #             mountpoint = "/";
  #             options = [ "noatime" ];
  #           };
  #         }
  #         {
  #           name = "home";
  #           type = "partition";
  #           start = "200G";
  #           end = "-1G";
  #           bootable = true;
  #           content = {
  #             type = "filesystem";
  #             format = "ext4";
  #             mountpoint = "/home";
  #             options = [ "noatime" ];
  #           };
  #         }
  #         {
  #           name = "swap";
  #           type = "partition";
  #           start = "-1G";
  #           end = "100%";
  #           content.type = "swap";
  #         }
  #       ];
  #     };
  #   };

  #   nodev = {
  #     "/media/games" = {
  #       device = "/dev/disk/by-uuid/8C1EE27F1EE261A6";
  #       fsType = "ntfs";
  #       options = [ "uid=1000" "gid=100" "rw" "user" "exec" "umask=000" "nofail" "lowntfs-3g" ];
  #     };
  #   };
  # };
}
