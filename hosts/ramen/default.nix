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
    theme.active = "autumnal";
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "hlissner";
      networks = [ "ca" "wg0" ];
      hardware = [
        "bluetooth"
        "wifi"
        "pc/laptop"
        "audio"
        "ssd"
      ];
    };

    desktop = {
      hyprland = rec {
        enable = true;
        monitors = [ { output = "eDP-1"; primary = true; } ];
        idle.time = 300;
        extraConfig = ''
          workspace=special:term,gapsin:3,gapsout:100,on-created-empty:hey .scratch term
          workspace=special:pad,gapsin:3,gapsout:40 80 40 80

          # trigger when the lid is up
          bindl=, switch:off:Lid Switch, exec, hyprctl dispatch dpms on
          # trigger when the lid is down
          bindl=, switch:on:Lid Switch, exec, hyprctl dispatch dpms off && hey .lock --no-fade-in --no-fade-out
        '';
      };

      apps.rofi.enable = true;
      term.default = "foot";
      term.foot.enable = true;

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
    virt.qemu.enable = true;
  };

  ## Local config
  config = { ... }: {
    systemd.network.networks.wg0.address = [ "10.10.0.2/32" ];
  };

  ## Hardware config
  hardware = { pkgs, ... }: {
    networking.wireless.interfaces = [ "wlp2s0" ];

    # If I want to sleep the system, I'll do it myself.
    services.logind.lidSwitch = "ignore";

    boot.initrd = {
      kernelModules = [ "dm-snapshot" ];
      luks.devices.home = {
        device = "/dev/nvme0n1p8";
        allowDiscards = true;
      };
    };

    # tlp is enabled by nixos-hardware.dell-xps-13-9370
    services.tlp.settings = {
      CPU_SCALING_GOVERNOR_ON_BAT="powersave";
      CPU_SCALING_GOVERNOR_ON_AC="ondemand";
      CPU_MAX_PERF_ON_AC=100;
      CPU_MAX_PERF_ON_BAT=50;

      # My laptop is always plugged in wherever I'm willing to use it, so I'll
      # value battery lifespan over runtime. Run `tlp fullcharge` to temporarily
      # force full charge.
      # @see https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
      START_CHARGE_THRESH_BAT0=40;
      STOP_CHARGE_THRESH_BAT0=50;
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
        neededForBoot = true;
      };
    };
    swapDevices = [ { device = "/dev/disk/by-label/swap"; }];
  };
}
