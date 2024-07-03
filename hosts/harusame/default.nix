# Harusame -- my workstation abroad

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  ## Dotfiles modules
  modules = {
    theme.active = "autumnal";
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
      ];
    };

    desktop = {
      # X only
      bspwm.enable = true;
      term.default = "xst";
      term.st.enable = true;

      # Wayland only
      # hyprland.enable = true;
      # term.default = "foot";
      # term.foot.enable = true;

      apps.rofi.enable = true;
      apps.spotify.enable = true;
      apps.steam = {
        enable = true;
        libraryDir = "/media/games/SteamLibrary";
      };
      apps.godot.enable = true;
      browsers.default = "firefox";
      browsers.firefox.enable = true;
      media.cad.enable = true;
      media.daw.enable = true;
      media.graphics.enable = true;
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
    virt.qemu.enable = true;
  };

  ## Local config
  config = { pkgs, ... }: {
    systemd.network.networks.wg0.address = [ "10.10.0.3/32" ];
  };

  ## Hardware config
  hardware = { ... }: {
    boot.supportedFilesystems = [ "ntfs" ];

    networking.interfaces.enp42s0.useDHCP = true;

    services.xserver = {
      # This must be done manually to ensure my screen spaces are arranged
      # exactly as I need them to be *and* the correct monitor is "primary".
      # Using xrandrHeads does not work.
      monitorSection = ''
        VendorName     "Unknown"
        ModelName      "Samsung S27E391"
        HorizSync       30.0 - 81.0
        VertRefresh     50.0 - 75.0
        Option         "DPMS"
      '';
      screenSection = ''
        Option "metamodes" "HDMI-0: nvidia-auto-select +1920+0, DP-1: 1920x1080_75 +0+0"
        Option "SLI" "Off"
        Option "MultiGPU" "Off"
        Option "BaseMosaic" "off"
        Option "Stereo" "0"
        Option "nvidiaXineramaInfoOrder" "DFP-1"
      '';
    };

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
