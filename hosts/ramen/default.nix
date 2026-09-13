# Ramen -- my laptop, for travel

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  imports = [
    hey.modules.nixos-hardware.dell-xps-13-9370
  ];

  ## Flake modules
  modules = {
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "ca" "ts0" ];
      hardware = [
        "bluetooth"
        "wifi"
        "pc/laptop"
        "audio"
        "ssd"
      ];
    };

    hyprland = {
      enable = true;
      plymouth = {
        enable = true;
        seamless = true;
      };
      monitors = [ { output = "eDP-1"; primary = true; } ];
      extraConfig = ''
        -- trigger when the lid is up
        -- hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "disable" }))
        -- trigger when the lid is down
        -- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms off && hey .lock --no-fade-in --no-fade-out"))
      '';
    };

    apps = {
      rofi.enable = true;
      term.default = "foot";
      term.foot.enable = true;

      browsers.default = "librewolf";
      browsers.librewolf.enable = true;
      media.cad.enable = true;
      # media.daw.enable = true;
      media.graphics.enable = true;
      media.music.enable = true;
      media.video.enable = true;
      # media.video.capture.enable = true;
      # media.pdf.enable = true;
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
      # vaultwarden.enable = true;
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    services = {
      ssh.enable = true;
      flatpak.enable = true;
    };
    system = {
      utils.enable = true;
    };
    # virt.qemu.enable = true;
  };

  ## Local config
  config = { ... }: {

  };

  ## Hardware config
  hardware = { pkgs, ... }: {
    # If I want to sleep the system, I'll do it myself.
    services.logind.settings.Login.HandleLidSwitch = "ignore";
    # Tapping power button should do nothing
    services.logind.settings.Login.HandlePowerKey = "ignore";

    boot.initrd = {
      kernelModules = [ "dm-snapshot" ];
      luks.devices.home = {
        device = "/dev/nvme0n1p8";
        allowDiscards = true;
      };
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
        neededForBoot = true;
      };
    };
    swapDevices = [ { device = "/dev/disk/by-label/swap"; }];
  };
}
