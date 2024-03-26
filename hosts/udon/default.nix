# Udon -- my primary powerhouse

{ self, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  modules = {
    theme.active = "alucard";
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "ca" ];
      hardware = [
        "cpu/amd"
        "gpu/nvidia"
        "audio"
        "audio/realtime"
        "ssd"
        "ergodox"
      ];
    };

    desktop = {
      bspwm.enable = true;

      apps.rofi.enable = true;
      apps.spotify.enable = true;
      apps.steam = {
        enable = true;
        libraryDir = "/media/windows/SteamLibrary";
      };
      browsers.default = "firefox";
      browsers.firefox.enable = true;
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
    system = {
      diagnostics.enable = true;
      fs.enable = true;
    };
    virt.qemu.enable = true;
  };

  ## Local config
  config = { ... }: {};

  hardware = { ... }: {
    boot.supportedFilesystems = [ "ntfs" ];

    # Disable all wakeup events to ensure restful sleep. This system has many
    # peripherals attached to it (shared between Windows and Linux) that can
    # unpredictably wake it.
    systemd.services.fixSuspend = {
      script = ''
        for ev in $(grep enabled /proc/acpi/wakeup | cut --delimiter=\  --fields=1); do
           echo $ev > /proc/acpi/wakeup
        done
      '';
      wantedBy = [ "multi-user.target" ];
    };
    # ...only wake-on-lan (and the power button) should wake it up.
    networking = {
      interfaces."eno1".wakeOnLan.enable = true;
      firewall.allowedUDPPorts = [ 9 ];
    };

    services.xserver = {
      # This must be done manually to ensure my screen spaces are arranged
      # exactly as I need them to be *and* the correct monitor is "primary".
      # Using xrandrHeads does not work.
      monitorSection = ''
        VendorName  "Unknown"
        ModelName   "DELL U2515H"
        HorizSync   30.0 - 113.0
        VertRefresh 56.0 - 86.0
        Option      "DPMS"
      '';
      screenSection = ''
        Option "metamodes" "HDMI-0: nvidia-auto-select +0+0, HDMI-1: nvidia-auto-select +1920+0, DP-1: nvidia-auto-select +4480+0"
        Option "SLI" "Off"
        Option "MultiGPU" "Off"
        Option "BaseMosaic" "off"
        Option "Stereo" "0"
        Option "nvidiaXineramaInfoOrder" "DFP-5"
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
      "/media/data" = {
        device = "/dev/disk/by-label/data";
        fsType = "ext4";
        options = [
          "noauto" "x-systemd.automount" "x-systemd.idle-timeout=15min" "x-systemd.mount-timeout=10s"
          "noatime" "nodev" "nosuid" "noexec"
        ];
      };
      "/media/video" = {
        device = "/dev/disk/by-label/video";
        fsType = "ntfs3";
        options = [
          "noauto" "x-systemd.automount" "x-systemd.idle-timeout=15min" "x-systemd.mount-timeout=10s"
          "uid=1000" "gid=100" "rw" "user" "exec" "umask=000"
        ];
      };
      "/media/windows" = {
        device = "/dev/disk/by-label/windows";
        fsType = "ntfs3";
        options = [
          "noauto" "x-systemd.automount" "x-systemd.idle-timeout=30min" "x-systemd.mount-timeout=10s"
          "uid=1000" "gid=100" "rw" "user" "exec" "umask=000"
        ];
      };
    };
    swapDevices = [];
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
