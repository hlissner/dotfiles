# Axiom -- C1's Ryzen 9950X + RTX 5090 workstation

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  ## Modules
  modules = {
    theme.active = "autumnal";
    xdg.ssh.enable = true;

    profiles = {
      role = "workstation";
      user = "c1";
      networks = [ "sh" ];
      hardware = [
        "cpu/amd"
        "gpu/nvidia"
        "audio"
        "audio/realtime"
        "ssd"
        "bluetooth"
        "wifi"
      ];
    };

    desktop = {
      bspwm.enable = true;
      apps = {
        rofi.enable = true;
        steam.enable = true;
      };
      input = {
        colemak.enable = true;
        fcitx5-rime.enable = true;
      };
      browsers = {
        default = "librewolf";
        librewolf.enable = true;
        chrome.enable = true;
      };
      term = {
        default = "foot";
        st.enable = true;
      };
      media.video.enable = true;
    };

    dev = {
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
      vscode.enable = true;
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
      docker.enable = true;
      calibre.enable = true;
    };
    system = {
      utils.enable = true;
      fs.enable = true;
    };
  };

  ## Local config
  config = { pkgs, ... }: {
    user.packages = with pkgs; [
      htop
      k9s
      kubectl
      nvtopPackages.nvidia
    ];

    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;

    networking.firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 7844 ];
      allowedTCPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
      allowedUDPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
    };
  };

  ## Hardware
  hardware = { ... }: {
    networking.networkmanager.enable = true;
    networking.interfaces.enp14s0.useDHCP = true;

    boot.supportedFilesystems = [ "ntfs" ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" ];
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

    swapDevices = [ ];
  };
}
