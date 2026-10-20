# lomein -- my living room guest, art, print/scan machine

{ self, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  modules = {
    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "ca" ];
      hardware = [
        "cpu/intel"
        "audio"
        "bluetooth"      # the keyboard and mouse
        "wifi"
        "wacom"          # Cintiq 21UX (DTK-2100) + Intuos Pro M (PTH-451)
        "printer/share"  # the LaserJet on USB, for the whole LAN
        "scanner"        # the other half of that MFP
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
          { output = "DVI-I-1";
            mode = "1920x1080";
            position = { x = 1920; y = 0; };
            primary = true; }
          { output = "DVI-I-2";
            mode = "1920x1080";
            position = { x = 0; y = 0; }; }
        ];
        # nouveau doesn't like the GT2XX and fails to render hardware cursors
        extraConfig = ''
          debug {
              disable-cursor-plane
          }
        '';
      };
    };

    apps = {
      term.default = "foot";
      term.foot = {
        enable = true;
        fontSize = 14;
      };
      flatpak.enable = true;
      rofi.enable = true;
      thunar.enable = true;        # guests expect a file manager
      libreoffice.enable = true;
      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
      media.graphics.enable = true;
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
    ## The guest account
    users.users.guest = {
      isNormalUser = true;
      description = "Guest";
      hashedPassword = "";
      group = "guest";
      extraGroups = [ "scanner" ];
      packages = config.user.packages;
    };
    users.groups.guest = {};
    security.pam.services.greetd.allowNullPassword = true;

    # nouveau doesn't display the hardware cursor
    services.greetd.settings.default_session.command =
      let greeter = config.services.displayManager.noctalia-greeter;
      in "${pkgs.coreutils}/bin/env WLR_NO_HARDWARE_CURSORS=1 "
         + "${getExe' greeter.package "noctalia-greeter-session"} ${escapeShellArgs greeter.extraArgs}";

    # So the guest account gets its own copy of the dotfiles
    systemd.services.hey-home-links-guest =
      let guest = config.users.users.guest;
          conf = "/etc/hey/links.conf";
      in {
        description = "Mirror the admin's home links into the guest's";
        wantedBy = [ "multi-user.target" ];
        after = [ "hey-home-links.service" ];
        restartTriggers = [ config.environment.etc."hey/links.conf".source ];
        unitConfig.RequiresMountsFor = guest.home;
        serviceConfig = { Type = "oneshot"; User = guest.name; };
        path = with pkgs; [ coreutils findutils gnused ];
        script = ''
          umask 077
          find "$HOME" -xdev \( -lname '/nix/store/*' -o -lname '${config.hey.configDir}/*' \) -delete
          sed 's|^${config.user.home}/|${guest.home}/|' ${conf} |
            while IFS=$'\t' read -r path target; do
              mkdir -p "''${path%/*}" && ln -sfn "$target" "$path"
            done
        '';
      };

    # For the HP LaserJet M28-30 printer
    services.ipp-usb.enable = true;
    hardware.printers = {
      ensurePrinters = [{
        name = "LaserJet";
        description = "HP LaserJet MFP M28-M31";
        location = "Living room";
        deviceUri = "ipp://localhost:60000/ipp/print";
        model = "everywhere";
      }];
      ensureDefaultPrinter = "LaserJet";
    };
  };

  hardware = { config, ... }: {
    # Apple's firmware boots \EFI\BOOT\BOOTX64.EFI and ignores efibootmgr
    boot.loader.efi.canTouchEfiVariables = false;

    hardware.graphics.enable = true;

    boot.initrd.kernelModules = [ "nouveau" ];
    # nouveau vendors every GSP blob from Pascal to Blackwell as module
    # firmware, so the initrd writes ~1.3 GB to /boot. Larger than the partition
    # is (1gb), so cut out all of it sicne the GTX 285 needs none of it.
    nixpkgs.overlays = [ (final: prev: {
      linux-firmware = final.runCommand "${prev.linux-firmware.name}-sans-nvidia"
        { passthru.compressFirmware = false; } ''
          mkdir -p $out/lib/firmware
          cd ${final.compressFirmwareZstd prev.linux-firmware}/lib/firmware
          for d in *; do [ "$d" = nvidia ] || ln -s "$PWD/$d" "$out/lib/firmware/$d"; done
        '';
    }) ];

    # For the AirPort card (Broadcom BCM4322)
    networking.enableB43Firmware = true;

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/root";
        fsType = "ext4";
        options = [ "noatime" "errors=remount-ro" ];
      };
      "/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
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
