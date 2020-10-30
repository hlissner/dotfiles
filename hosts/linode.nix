# 1. Create three (3) disk images:
#    - Installer: 1024mb
#    - Swap: 512mb
#    - NixOS: rest
#
# 2. Boot in rescue mode with:
#    - /dev/sda -> Installer
#    - /dev/sdb -> Swap
#    - /dev/sdc -> NixOS
#
# 3. Once booted into Finnix (step 2) pipe this script to sh:
#      iso=<nixos-64bit-iso-url>
#      update-ca-certificates
#      curl $url | dd of=/dev/sda
#
# 4. Install these dotfiles with
#      git clone https://github.com/hlissner/dotfiles ~/.config/dotfiles
#      nixos-install --root "$(PREFIX)" --flake ~/.config/dotfiles#linode
#
# 4. Create a configuration profile:
#    - Kernel: GRUB 2
#    - /dev/sda -> NixOS
#    - /dev/sdb -> Swap
#    - Helpers: distro and auto network helpers = off
#
# 5. Reboot into profile.

{ config, lib, pkgs, ... }:

with lib;
{
  environment.systemPackages =
    with pkgs; [ inetutils mtr sysstat git ];

  modules = {
    editors = {
      default = "nvim";
      vim.enable = true;
    };
    shell = {
      git.enable = true;
      zsh.enable = true;
    };
    services.ssh.enable = true;
  };

  # GRUB
  boot = {
    kernelParams = [ "console=ttyS0" ];
    loader = {
      timeout = 10;
      grub = {
        enable = true;
        version = 2;
        device = "nodev";
        copyKernels = true;
        fsIdentifier = "provided";
        extraConfig = "serial; terminal_input serial; terminal_output serial";
      };
      # Disable globals
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };
  };

  networking = {
    useDHCP = false;
    usePredictableInterfaceNames = false;
    interfaces.eth0.useDHCP = true;
  };
}
