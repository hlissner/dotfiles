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
#      git clone https://github.com/hlissner/dotfiles ~/.dotfiles
#      ln -s ~/.dotfiles /etc/dotfiles
#      cd ~/.dotfiles
#      mk install-linode
#
# 4. Create a configuration profile:
#    - Kernel: GRUB 2
#    - /dev/sda -> NixOS
#    - /dev/sdb -> Swap
#    - Helpers: distro and auto network helpers = off
#
# 5. Reboot into profile.

{ config, lib, pkgs, ... }:
{
  environment.systemPackages =
    with pkgs; [ inetutils mtr sysstat git ];

  imports = [
    ./common.nix
    <modules/editors/vim.nix>
    <modules/shell/git.nix>
    <modules/shell/zsh.nix>
    <modules/services/ssh.nix>
  ];

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

  networking.useDHCP = false;
  networking.usePredictableInterfaceNames = false;
  networking.interfaces.eth0.useDHCP = true;
}
