# Soba -- testbench and steam remote server

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
    hardware.common.cpu.intel
    hardware.common.gpu.nvidia
    hardware.common.audio
    hardware.common.ssd
  ];

  ## Flake modules
  modules = {
    theme.active = "alucard";

    desktop = {
      bspwm.enable = true;

      apps.rofi.enable = true;
      browsers.default = "firefox";
      browsers.firefox.enable = true;
      gaming.steam.enable = true;
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
      git.enable    = true;
      gnupg.enable  = true;
      tmux.enable   = true;
      zsh.enable    = true;
    };
    services = {
      ssh.enable = true;
    };
    virt.qemu.enable = true;
  };

  ## Local config
  config = { pkgs, ... }: {
    # Allow kernel options to be modified before booting. This is a testbench
    # system. Security is less important.
    boot.loader.systemd-boot = {
      editor = true;
      # Add memtest86 as a permanent boot option
      extraFiles."EFI/memtest86/memtest86.efi" = "${pkgs.memtest86-efi}/BOOTX64.efi";
      extraEntries."memtest86.conf" = ''
        title MemTest86
        efi /EFI/memtest86/memtest86.efi
      '';
    };
  };

  ## Hardware config
  hardware = { ... }: {
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
        options = [ "uid=1000" "gid=100" "rw" "user" "exec" "umask=000" "nofail" "lowntfs-3g" ];
      };
    };
    swapDevices = [{ device = "/dev/disk/by-label/swap"; }];
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
