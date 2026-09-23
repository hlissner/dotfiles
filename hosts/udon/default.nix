# Udon -- my primary powerhouse

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  modules = {
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
        "vr"
      ];
    };

    hyprland = {
      enable = true;
      plymouth = {
        enable = true;
        seamless = true;
      };
      monitors = [
        { output = "HDMI-A-2";
          mode = "2560x1440@120";
          position = "1920x2160";
          vrr = 2;
          primary = true; }
        { output = "DP-2";
          position = "0x2191"; }
        { output = "DP-3";
          position = "4480x2191"; }
        { output = "HDMI-A-1";
          mode = "3840x2160@120";
          position = "1280x0";
          vrr = 2;
          disabled = true; }
      ];
      extraConfig = ''
        -- Bind fixed workspaces to external monitors
        hl.workspace_rule({ workspace = "name:right",
                            monitor = "DP-3",
                            default = true,
                            persistent = true })
        hl.workspace_rule({ workspace = "name:left",
                            monitor = "DP-2",
                            default = true,
                            persistent = true })
        -- Staged for when the tv is switched on
        hl.workspace_rule({ workspace = "name:tv",
                            monitor = "HDMI-A-1",
                            default = true,
                            gaps_out = 4 })

        hl.device({ name = "apple-inc.-magic-trackpad",
                    natural_scroll = false,
                    scroll_method = "2fg",
                    scroll_factor = 0.75,
                    accel_profile = "adaptive",
                    sensitivity = 0.35,
                    clickfinger_behavior = true, -- 1fg = LMB, 2fg = RMB, 3fg = MMB
                    tap_to_click = true,
                    tap_and_drag = false,
                    tap_button_map = "lrm",
                    drag_lock = 2,
                    disable_while_typing = false })

        hl.config({
          -- To address 1px overscan on my U2724D's
          general = {
            gaps_out = { top = 0, left = 0, right = 1, bottom = 0 }
          }
        })
      '';
    };

    ai = {
      claude.enable = true;
    };

    apps = {
      term.default = "foot";
      term.foot.enable = true;

      ## Extra
      flatpak.enable = true;
      rofi.enable = true;
      thunar.enable = true;
      libreoffice.enable = true;
      steam = {
        enable = true;
        libraryDir = "/media/windows/Program Files (x86)/Steam";
      };
      godot.enable = true;

      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
      media.cad.enable = true;
      media.daw.enable = true;
      media.graphics.enable = true;
      media.music.enable = true;
      media.video.enable = true;
      # media.video.capture.enable = true;
      # media.pdf.enable = true;
    };
    dev = {
      cc.enable = true;
      lua.enable = true;
    };
    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };
    shell = {
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
    virt.qemu.enable = true;
  };

  ## local config
  config = { pkgs, ... }: {
    user.packages = with pkgs; [
      guitarix
      gxplugins-lv2
      ladspaPlugins
    ];

    programs.kdeconnect = {
      enable = true;
      package = pkgs.kdePackages.kdeconnect-kde;
    };
  };

  hardware = { ... }: {
    # Disable all USB wakeup events to ensure restful sleep. This system has
    # many peripherals attached to it (shared between Windows and Linux) that
    # can unpredictably wake it otherwise. Ensures *only* the power button can
    # wake it up.
    systemd.services.fixSuspend = {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for ev in $(grep enabled /proc/acpi/wakeup | cut --fields=1); do
           echo $ev > /proc/acpi/wakeup || true
        done
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # ...But sometimes the monitors will fall asleep and I'll forget I haven't
    # suspended the system so I'll press the power button thinking I'm waking it
    # up, only to initiate shutdown, so no-op the power button.
    services.logind.settings.Login.HandlePowerKey = "ignore";

    # For the Steam controller and (later) the Steam Frame.
    # hardware.steam-hardware.enable = true;

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

      "/media/data" = {
        device = "/dev/disk/by-label/data";
        fsType = "ext4";
        options = [ "noatime" "noauto" "nofail" "x-systemd.automount" ];
      };
      "/media/backup" = {
        device = "/dev/disk/by-label/backup";
        fsType = "ext4";
        options = [ "noatime" "noauto" "nofail" "x-systemd.automount" ];
      };
      # ntfs3 (in-kernel) > ntfs-3g (FUSE). Since my Steam library lives on this
      # partition, this saves steam the userspace round trip per IO.
      "/media/windows" = {
        device = "/dev/disk/by-label/windows";
        fsType = "ntfs3";
        options = ["noatime" "nodev" "nosuid" "exec" "umask=000" "uid=1000" "gid=100" "noauto" "nofail" "x-systemd.automount" ];
      };

      "/media/nas" = {
        device = "nas0.lan:/mnt/nas/users/hlissner/files";
        fsType = "nfs";
        options = [ "noauto" "nofail" "noatime" "nfsvers=4.2" "x-systemd.automount" "x-systemd.idle-timeout=600" ];
      };
      "/media/dl" = {
        device = "nas0.lan:/mnt/nas/media";
        fsType = "nfs";
        options = [ "noauto" "nofail" "noatime" "nfsvers=4.2" "x-systemd.automount" "x-systemd.idle-timeout=600" ];
      };
    };
    swapDevices = [];
  };
}
