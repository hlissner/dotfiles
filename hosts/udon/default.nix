# Udon -- my primary powerhouse

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  modules = {
    theme.active = "autumnal";
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
        "bluetooth"
      ];
    };

    desktop = {
      hyprland = rec {
        enable = true;
        monitors = [
          { output = "HDMI-A-2";
            mode = "2560x1440@120";
            position = "1920x2160";
            primary = true; }
          { output = "DP-2";
            position = "0x2191"; }
          { output = "DP-3";
            position = "4480x2191"; }
          { output = "HDMI-A-1";
            mode = "3840x2160@120";
            position = "1280x0"; }
        ];
        extraConfig = ''
          # REVIEW: Might be a hyprland bug, but an "Unknown-1" display is
          #   always created and reserves some desktop space, so I disable it.
          monitor = Unknown-1,disable

          # Bind fixed workspaces to external monitors
          workspace = name:left, monitor:DP-3, default:true
          workspace = name:right, monitor:DP-2, default:true
          workspace = name:tv, monitor:HDMI-A-1, default:true, gapsout:4

          # Scroll by holding down a side button, because the wheel is broken
          device {
              name = mosart-semi.-2.4g-wireless-mouse
              scroll_method = on_button_down
              scroll_button = 276
          }

          # To address 1px overscan on my U2724D's
          general {
            gaps_out = 0,0,1,0
          }

          exec-once = hyprctl keyword monitor HDMI-A-1,disable
        '';
      };
      term.default = "foot";
      term.foot.enable = true;

      ## Extra
      apps.rofi.enable = true;
      apps.thunar.enable = true;
      apps.libreoffice.enable = true;
      apps.steam = {
        enable = true;
        libraryDir = "/media/windows/Program Files (x86)/Steam";
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
      media.pdf.enable = true;
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
    user.packages = with pkgs; [
      guitarix
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
    # can unpredictably wake it otherwise. Ensures *only* the power button can
    # wake it up.
    systemd.services.fixSuspend = {
      script = ''
        for ev in $(grep enabled /proc/acpi/wakeup | cut --delimiter=\  --fields=1); do
           echo $ev > /proc/acpi/wakeup
        done
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # ...But sometimes the monitors will fall asleep and I'll forget I haven't
    # suspended the system so I'll press the power button thinking I'm waking it
    # up, only to initiate shutdown, so no-op the power button.
    services.logind.powerKey = "ignore";

    # services.xserver = {
    #   # This must be done manually to ensure my screen spaces are arranged
    #   # exactly as I need them to be *and* the correct monitor is "primary".
    #   # Using xrandrHeads does not work.
    #   monitorSection = ''
    #     VendorName  "Unknown"
    #     ModelName   "DELL U2515H"
    #     HorizSync   30.0 - 113.0
    #     VertRefresh 56.0 - 86.0
    #     Option      "DPMS"
    #   '';
    #   screenSection = ''
    #     Option "metamodes" "DP-5: nvidia-auto-select +0+31, HDMI-1: nvidia-auto-select +1920+0, DP-3: nvidia-auto-select +4480+31"
    #     Option "SLI" "Off"
    #     Option "MultiGPU" "Off"
    #     Option "BaseMosaic" "off"
    #     Option "Stereo" "0"
    #     Option "nvidiaXineramaInfoOrder" "DFP-5"
    #   '';
    # };

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
}
