# htpc -- my HTPC (shocker)

{ self, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  imports = [
    # Not exported by the flake, but it knows gen9 needs the legacy compute
    # runtime and the old VA-API driver (the new one can't do VP9 on Skylake).
    "${self.inputs.nixos-hardware}/common/cpu/intel/skylake"
  ];

  modules = {
    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "ca" ];
      hardware = [
        "cpu/intel"
        "gpu/nvidia"
        "audio"
        "ssd"
        "bluetooth"
      ];
    };

    wm = {
      desktop = "hyprland";
      hyprland = rec {
        monitors = [
          { output = "HDMI-A-2";
            mode = "preferred";
            primary = true; }
        ];
      };
    };

    apps = {
      term.default = "foot";
      term.foot.enable = true;

      ## Extra
      flatpak.enable = true;
      rofi.enable = true;
      steam.enable = true;

      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
    };
    shell = {
      git.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    services = {
      ssh.enable = true;
    };
    system = {
      utils.enable = true;
    };
  };

  ## local config
  config = { config, pkgs, ... }: {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
      dataDir = "${config.home.dir}/jellyfin";
      user = config.user.name;
    };

    # No AV1 decoder on this card
    programs.firefox.preferences."media.av1.enabled" = false;

    # Targets for shortcuts in Steam Big Picture
    user.packages = with pkgs; [
      (writeShellScriptBin "netflix" ''
        exec ${getExe config.programs.firefox.finalPackage} \
          --profile "${config.home.dataDir}/netflix" --kiosk "$@" \
          https://www.netflix.com
      '')
      (writeShellScriptBin "jellyfin" ''
        exec ${getExe jellyfin-desktop} --tv --fullscreen "$@"
      '')
    ];

    # Librewolf' turns DRM off and wipes cookies on exit. Undo that for the
    # kiosk only.
    home.dataFile."netflix/user.js".text = ''
      user_pref("media.eme.enabled", true);
      user_pref("media.eme.require-app-approval", false);
      user_pref("media.gmp-widevinecdm.enabled", true);
      user_pref("media.gmp-widevinecdm.visible", true);
      user_pref("media.gmp-widevinecdm.autoupdate", true);
      user_pref("media.gmp-manager.updateEnabled", true);
      user_pref("privacy.sanitize.sanitizeOnShutdown", false);
      user_pref("privacy.resistFingerprinting", false);
    '';

    # ExtensionSettings is a global policy, so the kiosk profile gets it too.
    modules.apps.browsers.librewolf.extensions."uBlock0@raymondhill.net" = {
      installation_mode = "normal_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    };

    # Auto-login. This is an HTPC. Get straight to the point.
    services.greetd.settings.initial_session = {
      user = config.user.name;
      command = "${getExe config.programs.uwsm.package} start -e -D Hyprland hyprland.desktop";
    };
    # ...and straight into Steam Big Picture
    systemd.user.services.steam-bigpicture = {
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [ "/run/wrappers" "/run/current-system/sw" ];
      serviceConfig = {
        # The wrapped steam from modules/apps/steam.nix, not pkgs.steam
        ExecStart = "/run/current-system/sw/bin/steam -bigpicture";
        Restart = "no";
      };
    };
  };

  hardware = { config, ... }: {
    # GTX 960 (Maxwell 2.0, GM206) requires v580
    hardware.nvidia = {
      open = false;  # Turing and later only
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };

    services.logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
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
      "/media/nas" = {
        device = "nas0.lan:/mnt/nas/users/hlissner/files";
        fsType = "nfs";
        options = [ "noauto" "nofail" "noatime" "nfsvers=4.2" "x-systemd.automount" "x-systemd.idle-timeout=600" ];
      };
    };
    swapDevices = [];
  };
}
