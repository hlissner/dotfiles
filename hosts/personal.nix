# hosts/personal.nix --- settings common to my personal systems

{ config, pkgs, ... }:
{
  imports = [
    ./.
    <modules/xdg.nix>
  ];

  # Support for more filesystems
  environment.systemPackages = with pkgs; [
    exfat
    ntfs3g
    hfsprogs
  ];

  # Nothing in /tmp should survive a reboot
  boot.tmpOnTmpfs = true;
  # Use simple bootloader; I prefer the on-demand BIOs boot menu
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ### Universal defaults
  networking.firewall.enable = true;
  networking.hosts = {
    "192.168.1.2"  = [ "ao" ];
    "192.168.1.3"  = [ "aka" ];
    "192.168.1.10" = [ "kuro" ];
    "192.168.1.11" = [ "shiro" ];
    "192.168.1.12" = [ "midori" ];
  };
}
