{ hey, lib, ... }:

{
  system = "x86_64-linux";

  modules = {
    profiles = {
      user = "c1";
      role = "server";
    };

    dev = {
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
    };

    editors = {
      default = "nvim";
      vim.enable = true;
    };

    shell = {
      adl.enable = true;
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };

    services = {
      ssh.enable = true;
      docker.enable = true;
      fail2ban.enable = true;
      nginx.enable = true;
    };

    theme.active = null;
    theme.useX = false;
  };

  config = { modulesPath, lib, pkgs, ... }: {
    imports = [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

    modules.agenix.sshKey = "/home/c1/.ssh/id_ed25519";

    boot = {
      growPartition = true;
      kernelParams = [ "console=ttyS0,115200n8" ];
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = false;
      };
    };

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };

    networking = {
      hostName = "aliyun-acorn";
      useDHCP = lib.mkForce false;
      firewall = {
        allowedTCPPorts = [ 22 80 443 34197 ];
        allowedUDPPorts = [ 34197 ];
      };
    };

    systemd.network = {
      enable = true;
      networks."10-aliyun-dhcp" = {
        matchConfig.Name = "eth* ens* enp*";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };

    services.cloud-init = {
      enable = true;
      network.enable = true;
      settings = {
        datasource_list = [ "AliYun" "NoCloud" "None" ];
      };
    };

    virtualisation.docker.enableOnBoot = lib.mkForce true;

    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
    security.acme.defaults.email = "siyuan.arc@gmail.com";

    time.timeZone = "Asia/Shanghai";

    systemd.services."serial-getty@ttyS0".enable = lib.mkForce true;
    systemd.services."getty@tty1".enable = lib.mkForce true;
    systemd.services."autovt@".enable = lib.mkForce true;

    systemd.services.cloud-init.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
    systemd.services.cloud-config.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
    systemd.services.cloud-final.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
  };
}
