# Ramen -- my mobile workstation, for when I travel

{ self, lib, profiles, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  ## Flake profiles
  profiles = with profiles; [
    role.workstation
    user.hlissner
    network.dk
    # network.vpn.homelab
    hardware.dell.xps."13-9370"
    hardware.common.pc.laptop.battery
    hardware.common.audio
    hardware.common.ssd
  ];

  ## Flake modules
  modules = {
    theme.active = "alucard";

    desktop = {
      bspwm.enable = true;

      apps.rofi.enable = true;
      apps.spotify.enable = true;
      browsers.default = "firefox";
      browsers.firefox.enable = true;
      gaming.steam.enable = true;
      media.cad.enable = true;
      media.daw.enable = true;
      media.graphics.enable = true;
      media.video.enable = true;
      media.video.capture.enable = true;
      term.default = "xst";
      term.st.enable = true;
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
      # docker.enable = true;
    };
    system.diagnostics.enable = true;
    virt.qemu.enable = true;
  };

  ## Local config
  config = { pkgs, ... }: {
    profiles.network.vpn.homelab = {
      ip = "10.10.0.2/24";
      privateKeyFile = config.age.secrets.wgHomelabKey.path;
    };
  };

  ## Hardware config
  hardware = { pkgs, ... }: {
    boot.initrd = {
      kernelModules = [ "dm-snapshot" ];
      luks.devices.home = {
        device = "/dev/nvme0n1p8";
        allowDiscards = true;
      };
    };

    networking.wireless.interfaces = [ "wlp2s0" ];

    # Control monitor brightness
    programs.light.enable = true;
    user.extraGroups = [ "video" ];

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
    };
    swapDevices = [ { device = "/dev/disk/by-label/swap"; }];
  };

  # Use 'hey install' to deploy these the first time, or 'hey install --storage'
  # to reformat an existing system.
  # storage = { ... }: {
  #   disk.sda = {
  #     device = "/dev/nvme0n1p8";
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
  #           end = "50%";
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
  #           start = "50%";
  #           end = "-4G";
  #           content = {
  #             name = "home";
  #             type = "luks";
  #             keyFile = "...";
  #             content = {
  #               type = "lvm_pv";
  #               vg = "pool";
  #             };
  #           };
  #         }
  #         {
  #           name = "swap";
  #           type = "partition";
  #           start = "-4G";
  #           end = "100%";
  #           content = {
  #             type = "swap";
  #           };
  #         }
  #       ];
  #     };
  #   };

  #   lvm_vg = {
  #     pool = {
  #       type = "lvm_vg";
  #       lvs = {
  #         home = {
  #           type = "lvm_lv";
  #           start = "1M";
  #           end = "100%";
  #           content = {
  #             type = "filesystem";
  #             format = "ext4";
  #             mountpoint = "/home";
  #             options = [ "noatime" ];
  #           };
  #         };
  #       };
  #     };
  #   };
  # };
}
