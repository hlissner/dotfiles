# hosts/default.nix
#
# Loads config common to all hosts.

{ config, lib, pkgs, ... }:

with lib;
with lib.my;
{
  ## Some reasonable, global defaults
  # This is here to appease 'nix flake check' for generic hosts with no
  # hardware-configuration.nix or fileSystem config.
  fileSystems."/".device = "/dev/disk/by-label/nixos";

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.configurationLimit = 10;
  };

  # Just the bear necessities...
  environment.systemPackages = with pkgs; [
    unstable.cached-nix-shell
    coreutils
    git
    vim
    wget
    gnumake
  ];

  networking.firewall.enable = true;
  networking.hosts =
    let hostConfig = {
          "192.168.1.2"  = [ "ao" ];
          "192.168.1.3"  = [ "aka" ];
          "192.168.1.10" = [ "kuro" ];
          "192.168.1.11" = [ "shiro" ];
          "192.168.1.12" = [ "midori" ];
        };
        hosts = flatten (attrValues hostConfig);
        hostName = config.networking.hostName;
    in mkIf (builtins.elem hostName hosts) hostConfig;

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;


  ## Location config -- since Toronto is my 127.0.0.1
  time.timeZone = lib.mkDefault "America/Toronto";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  # For redshift, mainly
  location = (if config.time.timeZone == "America/Toronto" then {
    latitude = 43.70011;
    longitude = -79.4163;
  } else if config.time.timeZone == "Europe/Copenhagen" then {
    latitude = 55.88;
    longitude = 12.5;
  } else {});


  ## System security tweaks
  boot.tmpOnTmpfs = true;
  security.hideProcessInformation = true;
  security.protectKernelImage = true;
  # Fix a security hole in place for backwards compatibility. See desc in
  # nixpkgs/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix
  boot.loader.systemd-boot.editor = false;

  # Change me later!
  user.initialPassword = "nix";
  users.users.root.initialPassword = "nix";
}
