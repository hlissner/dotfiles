# Udon -- my primary powerhouse

{ self, lib, ... }:

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

    wm = {
      desktop = "niri";
      plymouth = {
        enable = true;
        seamless = true;
      };
      niri = {
        monitors = [
          { output = "HDMI-A-2";
            mode = "2560x1440@120.000";
            position = { x = 1920; y = 2160; };
            vrr = "on-demand";
            primary = true; }
          { output = "DP-2";
            position = { x = 0; y = 2191; }; }
          { output = "DP-3";
            position = { x = 4480; y = 2191; }; }
          # For later, when I switch on the tv
          { output = "HDMI-A-1";
            mode = "3840x2160@120.000";
            position = { x = 1280; y = 0; };
            vrr = "on-demand";
            layout = "gaps 4";
            off = true; }
        ];
      };
    };

    ai.claude.enable = true;

    apps = {
      term.default = "foot";
      term.foot.enable = true;

      ## Extra
      flatpak.enable = true;
      rofi.enable = true;
      libreoffice.enable = true;
      godot.enable = true;
      # feishin.enable = true;
      supersonic.enable = true;

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
    games = {
      steam = {
        enable = true;
        libraryDir = "/media/data/SteamLibrary";
      };
      doom = {
        enable = true;
        wadsDir = "/media/nas/media/games/dos/doom";
      };
      emulators = let nas = "/media/nas/media/games"; in {
        enable = true;
        romsDir = nas;
        # EmuDeck's bios/ layout, which is what the cores expect of one flat
        # system dir. The console BIOSes still live in SYS/bios/ on the NAS;
        # link or copy them in here as a core complains.
        biosDir = "${nas}/_bios";
        systems = {
          nes = {}; snes = {}; genesis = {}; gamegear = {}; gba = {}; nds = {};
          n64 = {}; saturn = {}; psx = {}; psp = {}; ps2 = {}; ps3 = {}; wii = {};
          psvita = {}; switch = {};
          # Romm's slugs, not ES-DE's.
          mastersystem.path = "${nas}/sms/roms";
          dreamcast.path    = "${nas}/dc/roms";
          gc.path           = "${nas}/ngc/roms";
          n3ds.path         = "${nas}/3ds/roms";
          pico8.path        = "${nas}/pico/roms";
        };
      };
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
      vaultwarden.enable = true;
      yazi.enable = true;
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
  config = { pkgs, config, ... }: {
    programs.kdeconnect = {
      enable = true;
      package = pkgs.kdePackages.kdeconnect-kde;
    };

    home.dataLink =
      let games = config.modules.games.emulators;
          media = [ "covers" "backcovers" "screenshots" ];
      in optionalAttrs games.enable (
           { "eden/keys" = "${games.romsDir}/switch/bios/keys.22.1.0"; }
           // listToAttrs (concatMap
                (sys: map (m: nameValuePair "es-de/downloaded_media/${sys}/${m}"
                                            "${games.systems.${sys}.path}/${m}")
                          media)
                (attrNames games.systems)));

    user.packages = with pkgs; [
      guitarix
      gxplugins-lv2
      ladspaPlugins
    ];
  };

  hardware = { config, pkgs, ... }: {
    # Disable all USB wakeup events to ensure restful sleep. This system has
    # many peripherals attached to it (shared between Windows and Linux) that
    # can unpredictably wake it otherwise. Ensures *only* the power button can
    # wake it up.
    systemd.services.hey-fix-suspend = {
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

    # My realtek BT dongle wakes from system sleep and finds my BT devices (like
    # my apple trackpad), formerly connected before the system went to sleep,
    # "gone", so the dongle goes back to sleep. The trackpad responds to the
    # dongle's ACK but finds it asleep, so it goes back to sleep. The dongle
    # reacts to *that* response but find it asleep... Rinse and repeat. This
    # alone wasn't enough; the bluetooth profile's on-suspend hook does the rest.
    hey.hooks =
      let bctl = getExe' config.hardware.bluetooth.package "bluetoothctl";
          dir = "$XDG_RUNTIME_DIR/hey";
          marker = "${dir}/bt-powered";
      in {
        "on-suspend".bluetooth = ''
          rm -f ${marker}
          if ${bctl} show | grep -q 'Powered: yes'; then
            mkdir -p ${dir} && touch ${marker}
            ${bctl} power off >/dev/null
          fi
        '';
        "on-wakeup".bluetooth = ''
          [[ -f ${marker} ]] && ${bctl} power on >/dev/null
        '';
      };

    # ...But sometimes the monitors will fall asleep and I'll forget I haven't
    # suspended the system so I'll press the power button thinking I'm waking it
    # up, only to initiate shutdown, so no-op the power button.
    services.logind.settings.Login.HandlePowerKey = "ignore";

    # For the Steam controller
    hardware.steam-hardware.enable = true;
    # For 8BitDo SN30 Pro controller
    services.udev.packages = [ self.packages.udev-hid-bpf ];

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
      "/media/data1" = {
        device = "/dev/disk/by-label/data1";
        fsType = "ext4";
        options = [ "noatime" "noauto" "nofail" "x-systemd.automount" ];
      };
      "/media/backup" = {
        device = "/dev/disk/by-label/backup";
        fsType = "ext4";
        options = [ "noatime" "noauto" "nofail" "x-systemd.automount" ];
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
