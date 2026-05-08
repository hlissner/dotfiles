{ hey, lib, ... }:

with lib;
with builtins;
{

  system = "x86_64-linux";

  ## Modules
  modules = {
    theme.active = "autumnal";
    xdg.ssh.enable = true;
    # theme.useX = false;

    profiles = {
      role = "workstation";
      user = "c1";
      networks = [ "sh" ];
      hardware = [
        "cpu/amd"
        # "gpu/amd"
        "audio"
        "audio/realtime"
        "ssd"
      ];
    };
    # Sometimes it dies, and I need to see why.
    desktop = {
      hyprland.enable = true;
      apps = {
        rofi.enable = true;
      };
      input = {
        colemak.enable = true;
        fcitx5-rime.enable = true;
      };
      browsers = {
        zen.enable = true;
      };
      term = {
        default = "foot";
        foot.enable = true;
      };
    };
    dev = {
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
      # scala.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
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
      docker.enable = true;
      calibre.enable = true;
      # cloudflared.enable = true;
    };
    system = {
      utils.enable = true;
      fs.enable = true;
    };
  };
  ## Local config
  config = {pkgs, ...}: {

    user.packages = with pkgs; [
      k9s
      kubectl
    ];
    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;

    networking.firewall = {
      allowedTCPPorts = [ 22 ]; # SSH for cloudflared tunnel
      allowedUDPPorts = [ 7844 ]; # QUIC for cloudflared
      allowedTCPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
      allowedUDPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
    };

  #   # Cloudflare Tunnel configuration
  #   modules.services.cloudflared = {
  #     enable = true;
  #     # TODO: Replace with actual tunnel ID after running cloudflared-setup
  #     # tunnelId = "atlas-tunnel-id";
  #     # TODO: Create credentials file with agenix
  #     # credentialsFile = ./secrets/cloudflared-credentials.age;
  #     warpRouting = {
  #       enabled = true;
  #       cidrs = [ "192.168.50.0/24" ];
  #     };
  #     extraConfig = {
  #       tunnelName = "home-atlas";
  #     };
  #   };
  };

  ## hardware
  hardware = { ... }: {
    networking.interfaces.eno1.useDHCP = true;

    fileSystems."/" =
      { device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      { device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      };

    swapDevices = [ ];
  };

}
