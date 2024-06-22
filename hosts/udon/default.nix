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
        libraryDir = "/media/windows/Program Files (x86)/Steam";
      };
      apps.godot.enable = true;
      # apps.thunar.enable = true;
      # apps.gromit.enable = true;
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
      utils.enable = true;
      fs.enable = true;
    };
    # virt.qemu.enable = true;
  };

  ## local config
  config = { pkgs, ... }: {
    networking.search = [ "home.lissner.net" ];

    # Low-latency audio for guitar recording and DAW stuff. Should not be
    # generalized, since these values depend heavily on many local factors, like
    # CPU speed, kernels, audio cards, etc.
    environment.etc."pipewire/pipewire.conf.d/95-low-latency.conf".text = ''
      context.properties = {
        default.clock.rate = 48000
        default.clock.quantum = 64
        default.clock.min-quantum = 32
        default.clock.max-quantum = 64
      }
    '';

    user.packages = with pkgs; [
      unstable.guitarix
      gxplugins-lv2
      ladspaPlugins

      calibre
      signal-desktop
      zoom-us
    ];
  };

  hardware = { ... }: {
    boot.supportedFilesystems = [ "ntfs" ];

    networking.interfaces.eno1.useDHCP = true;

    # Disable all USB wakeup events to ensure restful sleep. This system has
    # many peripherals attached to it (shared between Windows and Linux) that
    # can unpredictably wake it otherwise.
    systemd.services.fixSuspend = {
      script = ''
        for ev in $(grep enabled /proc/acpi/wakeup | cut --delimiter=\  --fields=1); do
           echo $ev > /proc/acpi/wakeup
        done
      '';
      wantedBy = [ "multi-user.target" ];
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
        Option "metamodes" "DP-5: nvidia-auto-select +0+31, HDMI-1: nvidia-auto-select +1920+0, DP-3: nvidia-auto-select +4480+31"
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
      "/media/video" = {
        device = "/dev/disk/by-label/video";
        fsType = "ntfs";
        options = [ "defaults" "noauto" "nofail" "noatime" "nodev" "exec" "umask=000" "uid=1000" "gid=1000" "x-systemd.automount" ];
      };
      "/media/windows" = {
        device = "/dev/disk/by-label/windows";
        fsType = "ntfs";
        options = [ "defaults" "noauto" "nofail" "noatime" "nodev" "exec" "umask=000" "uid=1000" "gid=1000" "x-systemd.automount" ];
      };
      "/media/nas" = {
        device = "nas0.home.lissner.net:/mnt/nas/users/hlissner/files";
        fsType = "nfs";
        options = [ "noauto" "nofail" "noatime" "nfsvers=4.2" "x-systemd.automount" "x-systemd.idle-timeout=600" ];
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
